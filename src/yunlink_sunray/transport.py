"""Thin synchronous layer over the generic YunLink runtime."""

from __future__ import annotations

import queue
import threading
import time
import uuid
from collections.abc import Callable

import yunlink
from yunlink.core_codec import (
    decode_action_update,
    decode_attachment_response,
    decode_authority_status,
    decode_entity_directory,
    decode_stream_catalog,
    decode_stream_sample,
    decode_stream_subscription_status,
)

from .actions import ActionHandle
from .errors import AuthorityError, ConnectionError, DisconnectedError, TimeoutError
from .profiles import OFFERED_PROFILES, REQUIRED_PROFILES


def core_type(name: str) -> yunlink.TypeRef:
    return yunlink.TypeRef("yunlink.core", 2, name)


class Transport:
    def __init__(self, host: str, port: int, shared_secret: str, auto_reconnect: bool = True) -> None:
        endpoint_uid = f"python.{uuid.uuid4().hex}"
        self.runtime = yunlink.Runtime(yunlink.RuntimeConfig(
            endpoint_uid, 0, "yunlink-sunray", shared_secret,
            OFFERED_PROFILES, REQUIRED_PROFILES,
        ))
        self._host, self._port = host, port
        self._peer: yunlink.Peer | None = None
        self._session_id = 0
        self._remote_uid = ""
        self._condition = threading.Condition(threading.RLock())
        self._connected = False
        self._active_sessions: set[int] = set()
        self._responses: list[yunlink.Event] = []
        self._actions: dict[int, ActionHandle] = {}
        self._action_updates: dict[int, yunlink.ActionUpdate] = {}
        self._sample_callbacks: dict[str, list[Callable[[yunlink.Event, yunlink.StreamSample], None]]] = {}
        self._attached: set[str] = set()
        self._authorities: set[tuple[str, str]] = set()
        self._subscriptions: dict[str, tuple[str, str, float, int]] = {}
        self._closed = False
        self._auto_reconnect = auto_reconnect
        self._reconnecting = False
        self._event_thread = threading.Thread(target=self._event_loop, name="yunlink-events", daemon=True)
        self._event_thread.start()
        try:
            self._connect_session()
        except Exception:
            self.close()
            raise

    @property
    def session_id(self) -> int:
        return self._session_id

    @property
    def endpoint_uid(self) -> str:
        return self._remote_uid

    def _connect_session(self, timeout: float = 8.0) -> None:
        peer = self.runtime.connect(self._host, self._port)
        session_id = self.runtime.open_session(peer)
        with self._condition:
            self._peer, self._session_id = peer, session_id
            deadline = time.monotonic() + timeout
            while session_id not in self._active_sessions:
                remaining = deadline - time.monotonic()
                if remaining <= 0:
                    raise TimeoutError("YunLink session negotiation timed out")
                self._condition.wait(remaining)
            self._connected = True
        if not self.runtime.session_supports_profile(peer, session_id, "org.yunlink.mobility", 1, 0):
            raise ConnectionError("Bridge did not negotiate the Mobility Profile")
        if not self.runtime.session_supports_profile(peer, session_id, "com.yundrone.sunray", 2, 2):
            raise ConnectionError("Bridge did not negotiate a compatible Sunray Profile")
        self._remote_uid = self.runtime.session_endpoint_uid(peer, session_id)

    def _event_loop(self) -> None:
        while not self._closed:
            try:
                event = self.runtime.events.get(timeout=0.2)
            except queue.Empty:
                continue
            if event.kind == 3:
                with self._condition:
                    if event.session_state == 4:
                        self._active_sessions.add(event.session_id)
                    self._condition.notify_all()
            elif event.kind == 2 and not event.link_up and (
                self._peer is None or event.peer_id == self._peer.peer_id
            ):
                self._link_lost()
            elif event.kind == 1:
                self._envelope(event)

    def _envelope(self, event: yunlink.Event) -> None:
        callbacks: tuple[Callable[[yunlink.Event, yunlink.StreamSample], None], ...] = ()
        sample = None
        with self._condition:
            self._responses.append(event)
            if len(self._responses) > 512:
                del self._responses[:128]
            if event.family == yunlink.Family.ACTION and event.operation == 2:
                try:
                    update = decode_action_update(event.payload)
                except (ValueError, yunlink.CoreCodecError):
                    update = None
                if update is not None:
                    self._action_updates[event.correlation_id] = update
                    handle = self._actions.get(event.correlation_id)
                    if handle is not None:
                        handle._set_update(update)
                        if update.phase.terminal:
                            self._actions.pop(event.correlation_id, None)
                            self._action_updates.pop(event.correlation_id, None)
            elif event.family == yunlink.Family.STREAM and event.operation == 4:
                try:
                    sample = decode_stream_sample(event.payload)
                    callbacks = tuple(self._sample_callbacks.get(sample.stream_uid, ()))
                except (ValueError, yunlink.CoreCodecError):
                    sample = None
            self._condition.notify_all()
        if sample is not None:
            for callback in callbacks:
                try:
                    callback(event, sample)
                except Exception:  # noqa: BLE001,S112 - isolate user callbacks from the event pump
                    continue

    def _link_lost(self) -> None:
        with self._condition:
            if self._closed:
                return
            self._connected = False
            self._active_sessions.discard(self._session_id)
            for handle in self._actions.values():
                handle._set_disconnected()
            self._actions.clear()
            self._action_updates.clear()
            self._responses.clear()
            self._condition.notify_all()
            if not self._auto_reconnect or self._reconnecting:
                return
            self._reconnecting = True
        threading.Thread(target=self._reconnect, name="yunlink-reconnect", daemon=True).start()

    def _reconnect(self) -> None:
        with self._condition:
            attached = tuple(self._attached)
            authorities = tuple(self._authorities)
            subscriptions = tuple(self._subscriptions.values())
        while not self._closed:
            try:
                self._connect_session()
                with self._condition:
                    self._attached.clear()
                    self._authorities.clear()
                    self._subscriptions.clear()
                for entity_uid in attached:
                    self.attach(entity_uid)
                for entity_uid, scope in authorities:
                    self.claim_authority(entity_uid, scope)
                for entity_uid, stream_uid, rate, size in subscriptions:
                    self.subscribe(entity_uid, stream_uid, rate, size)
                break
            except Exception:  # noqa: BLE001 - reconnect retries every transport failure
                time.sleep(1.0)
        with self._condition:
            self._reconnecting = False

    def _publish(self, family: yunlink.Family, operation: int, target: yunlink.Target,
                 type_ref: yunlink.TypeRef, payload: bytes = b"", correlation_id: int = 0):
        with self._condition:
            if not self._connected or self._peer is None:
                raise DisconnectedError("YunLink session is not connected")
            peer, session_id = self._peer, self._session_id
        return self.runtime.publish(peer, session_id, family, operation, target, type_ref, payload,
                                    correlation_id=correlation_id, ttl_ms=5000)

    def request(self, family: yunlink.Family, operation: int, response_operation: int,
                target: yunlink.Target, type_ref: yunlink.TypeRef, payload: bytes = b"",
                timeout: float = 8.0) -> yunlink.Event:
        handle = self._publish(family, operation, target, type_ref, payload)
        deadline = time.monotonic() + timeout
        with self._condition:
            while True:
                for index, event in enumerate(self._responses):
                    if (event.correlation_id == handle.message_id and event.family == family
                            and event.operation == response_operation):
                        return self._responses.pop(index)
                if not self._connected:
                    raise DisconnectedError("connection was lost while waiting for a response")
                remaining = deadline - time.monotonic()
                if remaining <= 0:
                    raise TimeoutError(f"YunLink {family.name} request timed out")
                self._condition.wait(remaining)

    def directory(self) -> yunlink.EntityDirectory:
        event = self.request(yunlink.Family.ENTITY_DIRECTORY, 1, 2,
                             yunlink.Target.endpoint(self._remote_uid),
                             core_type("entity_directory.request"))
        return decode_entity_directory(event.payload)

    def attach(self, entity_uid: str) -> None:
        directory = self.directory()
        requested = tuple(sorted(self._attached | {entity_uid}))
        payload = yunlink.encode_core(yunlink.AttachmentRequest(directory.revision, requested))
        event = self.request(yunlink.Family.ENTITY_DIRECTORY, 4, 5,
                             yunlink.Target.endpoint(self._remote_uid),
                             core_type("attachment.request"), payload)
        response = decode_attachment_response(event.payload)
        if not response.success or entity_uid not in response.attached_entity_uids:
            raise ConnectionError(response.message or f"could not attach {entity_uid}")
        self._attached = set(response.attached_entity_uids)

    def claim_authority(self, entity_uid: str, scope: str) -> None:
        payload = yunlink.encode_core(yunlink.AuthorityRequest(scope, 300000, False))
        event = self.request(yunlink.Family.AUTHORITY, 1, 4, yunlink.Target.entity(entity_uid),
                             core_type("authority.request"), payload)
        status = decode_authority_status(event.payload)
        if status.state != "controller":
            raise AuthorityError(status.detail or f"authority rejected: {status.state}")
        self._authorities.add((entity_uid, scope))

    def catalog(self) -> yunlink.StreamCatalog:
        event = self.request(yunlink.Family.STREAM, 1, 2,
                             yunlink.Target.endpoint(self._remote_uid),
                             core_type("stream_catalog.request"))
        return decode_stream_catalog(event.payload)

    def subscribe(self, entity_uid: str, stream_uid: str, rate: float = 10.0,
                  max_payload_bytes: int = 65536) -> None:
        payload = yunlink.encode_core(yunlink.StreamSubscription(stream_uid, rate, max_payload_bytes))
        event = self.request(yunlink.Family.STREAM, 3, 6, yunlink.Target.entity(entity_uid),
                             core_type("stream.subscription"), payload)
        status = decode_stream_subscription_status(event.payload)
        if not status.success or not status.subscribed:
            raise ConnectionError(status.message or f"could not subscribe {stream_uid}")
        self._subscriptions[stream_uid] = (entity_uid, stream_uid, rate, max_payload_bytes)

    def on_sample(self, stream_uid: str,
                  callback: Callable[[yunlink.Event, yunlink.StreamSample], None]) -> None:
        self._sample_callbacks.setdefault(stream_uid, []).append(callback)

    def send_action(self, entity_uid: str, type_ref: yunlink.TypeRef, payload: bytes) -> ActionHandle:
        with self._condition:
            peer, session_id = self._peer, self._session_id
        if peer is None or not self.runtime.session_supports_profile(
            peer, session_id, type_ref.profile_id, type_ref.major, type_ref.minor
        ):
            raise ConnectionError(
                f"Bridge does not support {type_ref.profile_id}@{type_ref.major}.{type_ref.minor}"
            )
        self.claim_authority(entity_uid, type_ref.profile_id)
        message = self._publish(yunlink.Family.ACTION, 1, yunlink.Target.entity(entity_uid), type_ref, payload)
        handle = ActionHandle(message.message_id, lambda: self.cancel_action(entity_uid, type_ref, message.message_id))
        with self._condition:
            update = self._action_updates.pop(message.message_id, None)
            if update is not None:
                handle._set_update(update)
            if update is None or not update.phase.terminal:
                self._actions[message.message_id] = handle
        return handle

    def cancel_action(self, entity_uid: str, type_ref: yunlink.TypeRef, action_id: int) -> None:
        self._publish(yunlink.Family.ACTION, 3, yunlink.Target.entity(entity_uid), type_ref,
                      correlation_id=action_id)

    def close(self) -> None:
        with self._condition:
            if self._closed:
                return
            self._closed = True
            for handle in self._actions.values():
                handle._set_disconnected()
            self._condition.notify_all()
        if self._peer is not None:
            self.runtime.close_peer(self._peer)
        self.runtime.close()

    def __enter__(self) -> Transport:  # noqa: PYI034 - Python 3.10 has no typing.Self
        return self

    def __exit__(self, *_args: object) -> None:
        self.close()

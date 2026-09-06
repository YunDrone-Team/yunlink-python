"""Small UGV convenience API built on the existing Sunray UGV actions."""

from __future__ import annotations

import dataclasses
import threading
import time
from collections.abc import Callable

import yunlink
from yunlink.profiles.com.yundrone.sunray.v2 import sunray_pb2
from yunlink.profiles.org.yunlink.mobility.v1 import mobility_pb2

from .actions import ActionHandle, ActionResult
from .errors import ActionFailedError, ConnectionError
from .profiles import (
    PLANNER_CANCEL,
    UGV_HOLD,
    UGV_MOVE_POINT,
    UGV_VELOCITY,
    planner_cancel_payload,
    ugv_hold_payload,
    ugv_move_point_payload,
    ugv_velocity_payload,
)
from .state import StateStore, UgvState, Vector3
from .transport import Transport


class Ugv:
    def __init__(self, transport: Transport, uid: str) -> None:
        self._transport = transport
        self.uid = uid
        self._state = _UgvStateStore()
        self._last_action: ActionHandle | None = None
        self._lock = threading.Lock()
        transport.on_connection_change(self._on_connection)
        transport.attach(uid)
        self._state.set_connected(True)
        self._subscribe("odometry", self._on_odometry)
        self._subscribe("ugv_control_state", self._on_control_state)
        self._subscribe("ugv_planning_state", self._on_planning_state)

    @property
    def state(self) -> UgvState:
        return self._state.value

    def on_state_changed(self, callback: Callable[[UgvState], None]) -> Callable[[], None]:
        return self._state.on_change(callback)

    def move_to(self, x: float, y: float, *, frame_id: str | None = None, yaw_rad: float = 0.0,
                timeout: float = 60.0, wait: bool = True) -> ActionResult | ActionHandle:
        frame = frame_id or self.state.frame_id
        if not frame:
            raise ConnectionError("UGV odometry frame is not available; pass frame_id")
        return self._run(UGV_MOVE_POINT, ugv_move_point_payload(x, y, frame_id=frame, yaw_rad=yaw_rad), timeout, wait)

    def velocity(self, vx: float, vy: float = 0.0, *, duration_s: float | None = 1.0,
                 body: bool = False, frame_id: str | None = None, yaw_rate_radps: float = 0.0,
                 timeout: float = 15.0, wait: bool = True) -> ActionResult | ActionHandle:
        payload = ugv_velocity_payload(
            vx, vy, body=body, frame_id=frame_id or self.state.frame_id or "world",
            yaw_rate_radps=yaw_rate_radps,
        )
        handle = self._run(UGV_VELOCITY, payload, timeout, False)
        def refresh() -> None:
            deadline = None if duration_s is None else time.monotonic() + duration_s
            try:
                while not handle.done and (deadline is None or time.monotonic() < deadline):
                    time.sleep(0.2)
                    if not handle.done:
                        self._transport.refresh_action(self.uid, UGV_VELOCITY, payload, handle.action_id)
                if deadline is not None and not handle.done:
                    handle.cancel()
            except Exception:  # noqa: BLE001
                handle._set_disconnected()
        threading.Thread(target=refresh, name="yunlink-ugv-refresh", daemon=True).start()
        return handle.wait(timeout) if wait else handle

    def hold(self, timeout: float = 15.0, *, wait: bool = True) -> ActionResult | ActionHandle:
        return self._run(UGV_HOLD, ugv_hold_payload(), timeout, wait)

    def cancel(self, timeout: float = 15.0) -> ActionResult:
        with self._lock:
            handle = self._last_action
        if handle is None or handle.done:
            from yunlink.profiles.com.yundrone.sunray.v2 import sunray_pb2

            event = self._transport.call_rpc(
                self.uid,
                PLANNER_CANCEL,
                planner_cancel_payload(),
                authority_scope="com.yundrone.sunray",
                timeout=timeout,
            )
            response = sunray_pb2.PlannerCancelTaskResponse.FromString(event.payload)
            if not response.accepted:
                raise ActionFailedError(5, response.message or "Planner rejected cancellation")
            return ActionResult(0, yunlink.ActionPhase.SUCCEEDED, 0, response.message)
        handle.cancel()
        return handle.wait(timeout)

    def _subscribe(self, suffix: str, callback) -> None:
        stream = f"{self.uid}.{suffix}"
        self._transport.on_sample(stream, callback)
        self._transport.subscribe(self.uid, stream)

    def _run(self, type_ref, payload: bytes, timeout: float, wait: bool):
        handle = self._transport.send_action(
            self.uid, type_ref, payload, authority_scope="org.yunlink.mobility"
        )
        with self._lock:
            self._last_action = handle
        return handle.wait(timeout) if wait else handle

    def _on_connection(self, connected: bool) -> None:
        self._state.update(connected=connected)

    def _on_odometry(self, _event, sample) -> None:
        message = mobility_pb2.Odometry.FromString(sample.data)
        self._state.update(frame_id=message.frame_id,
                           position=Vector3(message.pose.position.x, message.pose.position.y, message.pose.position.z),
                           velocity=Vector3(message.twist.linear.x, message.twist.linear.y, message.twist.linear.z))

    def _on_control_state(self, _event, sample) -> None:
        self._state.update(control_state=sunray_pb2.UgvControlState.FromString(sample.data).fsm_state)

    def _on_planning_state(self, _event, sample) -> None:
        self._state.update(planner_state=sunray_pb2.UgvPlanningState.FromString(sample.data).task_state)


class _UgvStateStore(StateStore):
    def __init__(self) -> None:
        super().__init__()
        self._state = UgvState()

    def update(self, **changes: object) -> None:
        with self._condition:
            self._state = dataclasses.replace(self._state, received_at=time.time(), **changes)
            callbacks = tuple(self._callbacks)
            self._condition.notify_all()
        for callback in callbacks:
            callback(self._state)

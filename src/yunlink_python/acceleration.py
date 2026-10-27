"""Sample-driven acceleration compensation, independent of the motion action."""

from __future__ import annotations

from contextlib import suppress

import yunlink

from .actions import ActionHandle, ActionResult
from .errors import YunLinkPythonError
from .profiles import ACCELERATION_COMPENSATION, acceleration_compensation_payload
from .transport import Transport


class AccelerationControl:
    """World NED m/s², gravity-free. No automatic resend or reconnect replay.

    Call update() for each new algorithm output, typically at 100 Hz. After
    300 ms without a new sample the Bridge expires this channel. Cancel only
    removes compensation; the vehicle's original motion reference continues.
    """

    def __init__(self, transport: Transport, uid: str, ax: float, ay: float, az: float):
        self._transport, self._uid = transport, uid
        self.action: ActionHandle = transport.send_action(
            uid, ACCELERATION_COMPENSATION, acceleration_compensation_payload(ax, ay, az),
            authority_scope="com.yundrone.sunray", ttl_ms=300,
        )

    def update(self, ax: float, ay: float, az: float) -> None:
        payload = acceleration_compensation_payload(ax, ay, az)
        if self.action.done:
            self.action.wait(0)  # Surface rejection, expiry, or disconnection.
            raise ValueError("acceleration channel is closed; open a new channel explicitly")
        self._transport.update_action(
            self._uid, ACCELERATION_COMPENSATION, payload, self.action.action_id, ttl_ms=300,
        )

    def cancel(self, timeout: float = 3.0) -> ActionResult:
        self.action.cancel()
        return self.action.wait(timeout)

    def __enter__(self) -> AccelerationControl:  # noqa: PYI034 - Python 3.10 has no Self
        return self

    def __exit__(self, exc_type, _exc, _traceback) -> None:
        if exc_type is None:
            self.cancel()
        elif not self.action.done:
            with suppress(YunLinkPythonError, yunlink.Error):
                self.action.cancel()

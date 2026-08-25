"""Sunray UAV convenience API."""

from __future__ import annotations

import math
import threading
import time
from collections.abc import Callable, Sequence

from yunlink.profiles.com.yundrone.sunray.v2 import sunray_pb2
from yunlink.profiles.org.yunlink.mobility.v1 import mobility_pb2

from .actions import ActionHandle, ActionResult
from .errors import ConnectionError, TimeoutError
from .profiles import (
    HOVER,
    LAND,
    NAV_GOAL,
    TAKEOFF,
    WAYPOINT_MISSION,
    Waypoint,
    hover_payload,
    land_payload,
    nav_payload,
    takeoff_payload,
    waypoint_payload,
)
from .state import PlannerState, StateStore, Vector3, VehicleState
from .transport import Transport


class Vehicle:
    def __init__(self, transport: Transport, uid: str) -> None:
        self._transport = transport
        self.uid = uid
        self._state = StateStore()
        self._last_action: ActionHandle | None = None
        self._action_lock = threading.Lock()
        transport.attach(uid)
        self._subscribe("odometry", self._on_odometry)
        self._subscribe("flight_control_state", self._on_flight_state)
        self._subscribe("uav_planning_state", self._on_planning_state)

    @property
    def state(self) -> VehicleState:
        return self._state.value

    def on_state_changed(self, callback: Callable[[VehicleState], None]) -> Callable[[], None]:
        return self._state.on_change(callback)

    def takeoff(
        self, height_m: float = 1.5, timeout: float = 30.0, *, wait: bool = True
    ) -> ActionResult | ActionHandle:
        return self._run(TAKEOFF, takeoff_payload(height_m), timeout, wait)

    def hover(self, timeout: float = 15.0, *, wait: bool = True) -> ActionResult | ActionHandle:
        return self._run(HOVER, hover_payload(), timeout, wait)

    def land(self, timeout: float = 30.0, *, wait: bool = True) -> ActionResult | ActionHandle:
        return self._run(LAND, land_payload(), timeout, wait)

    def move_to(
        self,
        x: float,
        y: float,
        z: float,
        yaw_rad: float = 0.0,
        timeout: float = 60.0,
        *,
        frame_id: str | None = None,
        tolerance_m: float = 0.25,
        wait: bool = True,
    ) -> ActionResult | ActionHandle:
        if not math.isfinite(tolerance_m) or tolerance_m <= 0:
            raise ValueError("tolerance_m must be a positive finite value")
        frame = frame_id or self.state.frame_id
        if not frame:
            raise ConnectionError("odometry frame is not available; wait for vehicle state or pass frame_id")
        started = time.monotonic()
        result = self._run(NAV_GOAL, nav_payload(x, y, z, yaw_rad, frame), timeout, wait)
        if not wait:
            return result
        remaining = timeout - (time.monotonic() - started)
        if remaining <= 0:
            raise TimeoutError("move_to timed out before the vehicle reached the target")
        self._state.wait_for(
            lambda state: self._distance(state.position, Vector3(x, y, z)) <= tolerance_m,
            remaining,
        )
        return result

    def waypoint(
        self,
        x: float,
        y: float,
        z: float,
        yaw_rad: float = 0.0,
        hold_time_s: float = 0.0,
        timeout: float = 120.0,
        *,
        frame_id: str | None = None,
        task_name: str = "Python waypoint mission",
        wait: bool = True,
    ) -> ActionResult | ActionHandle:
        return self.waypoints(
            [Waypoint(x, y, z, yaw_rad, hold_time_s)],
            timeout=timeout,
            frame_id=frame_id,
            task_name=task_name,
            wait=wait,
        )

    def waypoints(
        self,
        points: Sequence[Waypoint],
        timeout: float = 120.0,
        *,
        frame_id: str | None = None,
        task_name: str = "Python waypoint mission",
        wait: bool = True,
    ) -> ActionResult | ActionHandle:
        frame = frame_id or self.state.frame_id
        if not frame:
            raise ConnectionError("odometry frame is not available; wait for vehicle state or pass frame_id")
        return self._run(
            WAYPOINT_MISSION,
            waypoint_payload(points, frame, task_name),
            timeout,
            wait,
        )

    def cancel(self, timeout: float = 15.0) -> ActionResult | None:
        with self._action_lock:
            handle = self._last_action
        if handle is not None and not handle.done:
            handle.cancel()
            return handle.wait(timeout)
        return self.hover(timeout=timeout)

    def _subscribe(self, suffix: str, callback) -> None:
        stream_uid = f"{self.uid}.{suffix}"
        self._transport.on_sample(stream_uid, callback)
        self._transport.subscribe(self.uid, stream_uid)

    def _run(self, type_ref, payload: bytes, timeout: float, wait: bool):
        handle = self._transport.send_action(self.uid, type_ref, payload)
        with self._action_lock:
            self._last_action = handle
        return handle.wait(timeout) if wait else handle

    def _on_odometry(self, _event, sample) -> None:
        message = mobility_pb2.Odometry()
        message.ParseFromString(sample.data)
        self._state.update(
            frame_id=message.frame_id,
            position=Vector3(message.pose.position.x, message.pose.position.y, message.pose.position.z),
            velocity=Vector3(message.twist.linear.x, message.twist.linear.y, message.twist.linear.z),
        )

    def _on_flight_state(self, _event, sample) -> None:
        message = sunray_pb2.FlightControlState()
        message.ParseFromString(sample.data)
        self._state.update(
            armed=message.armed,
            landed=message.landed,
            battery_voltage_v=message.battery_voltage_v,
            battery_percent=message.battery_percent,
            control_mode=message.control_mode,
            control_state=message.control_state,
        )

    def _on_planning_state(self, _event, sample) -> None:
        message = sunray_pb2.UavPlanningState()
        message.ParseFromString(sample.data)
        self._state.update(
            planner=PlannerState(
                main_state=message.main_state,
                task_state=message.task_state,
                task_name=message.task_name,
                current_waypoint_index=message.current_waypoint_index,
                total_waypoints=message.total_waypoints,
                distance_to_goal_m=message.distance_to_goal_m,
                hold_remaining_s=message.hold_remaining_s,
                failure_reason=message.failure_reason,
            )
        )

    @staticmethod
    def _distance(left: Vector3, right: Vector3) -> float:
        return math.sqrt(
            (left.x - right.x) ** 2 + (left.y - right.y) ** 2 + (left.z - right.z) ** 2
        )

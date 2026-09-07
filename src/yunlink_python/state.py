"""Small immutable state model exposed to scripts and MATLAB."""

from __future__ import annotations

import dataclasses
import threading
import time
from collections.abc import Callable

from .errors import TimeoutError


@dataclasses.dataclass(frozen=True)
class Vector3:
    x: float = 0.0
    y: float = 0.0
    z: float = 0.0


@dataclasses.dataclass(frozen=True)
class Quaternion:
    x: float = 0.0
    y: float = 0.0
    z: float = 0.0
    w: float = 1.0


@dataclasses.dataclass(frozen=True)
class LocalizationState:
    valid: bool = False
    source: int = 0
    update_hz: float = 0.0
    message: str = ""


@dataclasses.dataclass(frozen=True)
class PlannerState:
    main_state: int = 0
    task_state: int = 0
    task_name: str = ""
    current_waypoint_index: int = 0
    total_waypoints: int = 0
    distance_to_goal_m: float = 0.0
    hold_remaining_s: float = 0.0
    failure_reason: str = ""


@dataclasses.dataclass(frozen=True)
class VehicleState:
    frame_id: str = ""
    position: Vector3 = Vector3()
    velocity: Vector3 = Vector3()
    attitude: Quaternion = Quaternion()
    angular_velocity: Vector3 = Vector3()
    armed: bool = False
    landed: bool = True
    battery_voltage_v: float = 0.0
    battery_percent: int = 0
    control_mode: int = 0
    control_mode_name: str = ""
    control_state: int = 0
    movement_mode: str = ""
    px4_mode: str = ""
    manual_override: bool = False
    controller_type: int = 0
    localization: LocalizationState = LocalizationState()
    planner: PlannerState = PlannerState()
    received_at: float = 0.0
    connected: bool = False

    @property
    def disarmed(self) -> bool:
        """Read-only inverse of the controller-reported arm state."""
        return not self.armed

    @property
    def landing(self) -> bool:
        """Whether the controller reports an active landing phase."""
        return not self.landed and self.movement_mode == "land"

    @property
    def fresh(self) -> bool:
        return self.is_fresh()

    def is_fresh(self, max_age_s: float = 1.5) -> bool:
        return self.connected and self.received_at > 0 and time.time() - self.received_at <= max_age_s


@dataclasses.dataclass(frozen=True)
class UgvState:
    frame_id: str = ""
    position: Vector3 = Vector3()
    velocity: Vector3 = Vector3()
    control_state: int = 0
    planner_state: int = 0
    received_at: float = 0.0
    connected: bool = False

    def is_fresh(self, max_age_s: float = 1.5) -> bool:
        return self.connected and self.received_at > 0 and time.time() - self.received_at <= max_age_s


class StateStore:
    def __init__(self) -> None:
        self._condition = threading.Condition()
        self._state = VehicleState()
        self._callbacks: list[Callable[[VehicleState], None]] = []

    @property
    def value(self) -> VehicleState:
        with self._condition:
            return self._state

    def update(self, **changes: object) -> None:
        with self._condition:
            self._state = dataclasses.replace(self._state, received_at=time.time(), **changes)
            state, callbacks = self._state, tuple(self._callbacks)
            self._condition.notify_all()
        for callback in callbacks:
            callback(state)

    def on_change(self, callback: Callable[[VehicleState], None]) -> Callable[[], None]:
        with self._condition:
            self._callbacks.append(callback)
        def unsubscribe() -> None:
            with self._condition:
                if callback in self._callbacks:
                    self._callbacks.remove(callback)
        return unsubscribe

    def wait_for(self, predicate: Callable[[VehicleState], bool], timeout: float) -> VehicleState:
        deadline = time.monotonic() + timeout
        with self._condition:
            while not predicate(self._state):
                remaining = deadline - time.monotonic()
                if remaining <= 0:
                    raise TimeoutError("vehicle state condition timed out")
                self._condition.wait(remaining)
            return self._state

    def set_connected(self, connected: bool) -> None:
        self.update(connected=connected)

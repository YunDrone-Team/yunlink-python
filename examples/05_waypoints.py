"""发送多航点 Planner 任务，并实时打印进度。"""

from __future__ import annotations

import os

from yunlink_python import Waypoint, connect, discover_and_connect

address = os.getenv("YUNLINK_ADDRESS")
client = connect(address) if address else discover_and_connect(timeout=1.5)
with client:
    vehicle = client.vehicle(os.getenv("YUNLINK_VEHICLE", "uav1"))
    height = 1.0
    try:
        vehicle.takeoff(height, timeout=30)

        def show(state) -> None:
            planner = state.planner
            print(
                f"planner main={planner.main_state} task={planner.task_state} "
                f"waypoint={planner.current_waypoint_index + 1}/{planner.total_waypoints} "
                f"distance={planner.distance_to_goal_m:.2f} "
                f"hold={planner.hold_remaining_s:.1f}s failure={planner.failure_reason!r}"
            )

        unsubscribe = vehicle.on_state_changed(show)
        try:
            start = vehicle.state.position
            result = vehicle.waypoints(
                [
                    Waypoint(start.x + 0.25, start.y, height, hold_time_s=0.5),
                    Waypoint(start.x + 0.25, start.y + 0.25, height, hold_time_s=0.5),
                ],
                timeout=120,
            )
            print("mission result:", result)
        finally:
            unsubscribe()
    finally:
        if not vehicle.state.landed:
            vehicle.land(timeout=30)

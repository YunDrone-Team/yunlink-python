"""发送多航点 Planner 任务，并实时打印进度。"""

from __future__ import annotations

import argparse

from _session import add_connection_arguments, open_bridge, select_uav

from yunlink_python import Waypoint

parser = argparse.ArgumentParser(description="执行 UAV 多航点 Planner 任务")
add_connection_arguments(parser)
args = parser.parse_args()

with open_bridge(args.address) as client:
    # 必须先从目录确认目标 UAV，再 attach 后提交航点任务。
    vehicle = select_uav(client, args.entity)
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

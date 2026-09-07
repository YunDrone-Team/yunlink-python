"""持续读取 UAV 快照，并演示状态订阅回调。"""

from __future__ import annotations

import argparse
import os
import time

from yunlink_python import connect, discover_and_connect

parser = argparse.ArgumentParser()
parser.add_argument("--seconds", type=float, default=10.0)
args = parser.parse_args()

address = os.getenv("YUNLINK_ADDRESS")
client = connect(address) if address else discover_and_connect(timeout=1.5)
with client:
    vehicle = client.vehicle(os.getenv("YUNLINK_VEHICLE", "uav1"))
    last_print = [0.0]

    def show(state) -> None:
        now = time.monotonic()
        if now - last_print[0] < 0.5:
            return
        last_print[0] = now
        p = state.position
        print(
            f"connected={state.connected} fresh={state.fresh} "
            f"pos=({p.x:.2f}, {p.y:.2f}, {p.z:.2f}) "
            f"landed={state.landed} battery={state.battery_percent}% "
            f"planner={state.planner.task_state} distance={state.planner.distance_to_goal_m:.2f}"
        )

    unsubscribe = vehicle.on_state_changed(show)
    try:
        deadline = time.monotonic() + args.seconds
        while time.monotonic() < deadline:
            time.sleep(0.5)
    finally:
        unsubscribe()

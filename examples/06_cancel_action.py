"""启动非阻塞 Planner Action，查看进度，然后取消当前任务。"""

from __future__ import annotations

import argparse
import os
import time

from yunlink_sunray import connect, discover_and_connect

parser = argparse.ArgumentParser()
parser.add_argument("--after", type=float, default=2.0, help="开始任务后等待多少秒再取消")
args = parser.parse_args()

address = os.getenv("YUNLINK_ADDRESS")
client = connect(address) if address else discover_and_connect(timeout=1.5)
with client:
    vehicle = client.vehicle(os.getenv("YUNLINK_VEHICLE", "uav1"))
    try:
        vehicle.takeoff(1.0, timeout=30)
        start = vehicle.state.position
        handle = vehicle.move_to(start.x + 1.0, start.y, 1.0, timeout=90, wait=False)
        deadline = time.monotonic() + args.after
        while not handle.done and time.monotonic() < deadline:
            print(f"action={handle.action_id} phase={handle.phase.name} progress={handle.progress}% detail={handle.detail}")
            time.sleep(0.25)
        print("cancel result:", vehicle.cancel(timeout=25))
        print(f"final phase={handle.phase.name} detail={handle.detail}")
    finally:
        if not vehicle.state.landed:
            vehicle.land(timeout=30)

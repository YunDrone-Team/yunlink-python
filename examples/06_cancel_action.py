"""启动非阻塞 Planner Action，查看进度，然后取消当前任务。"""

from __future__ import annotations

import argparse
import time

from _session import add_connection_arguments, open_bridge, select_uav

parser = argparse.ArgumentParser()
parser.add_argument("--after", type=float, default=2.0, help="开始任务后等待多少秒再取消")
add_connection_arguments(parser)
args = parser.parse_args()

with open_bridge(args.address) as client:
    # 取消示例也必须针对明确的 UAV，不会默认取消第一台设备的任务。
    vehicle = select_uav(client, args.entity)
    try:
        vehicle.takeoff(1.0, timeout=30)
        start = vehicle.state.position
        handle = vehicle.move_to(start.x + 1.0, start.y, 1.0, timeout=90, wait=False)
        deadline = time.monotonic() + args.after
        while not handle.done and time.monotonic() < deadline:
            print(
                f"action={handle.action_id} phase={handle.phase.name} progress={handle.progress}% detail={handle.detail}"
            )
            time.sleep(0.25)
        print("cancel result:", vehicle.cancel(timeout=25))
        print(f"final phase={handle.phase.name} detail={handle.detail}")
    finally:
        if not vehicle.state.landed:
            vehicle.land(timeout=30)

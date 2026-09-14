"""完整 UAV 基础控制：起飞、前后左右上下、目标移动、悬停、降落。"""

from __future__ import annotations

import argparse

from _session import add_connection_arguments, open_bridge, select_uav

from yunlink_python import run_with_status

parser = argparse.ArgumentParser(description="执行 UAV 基础控制动作")
add_connection_arguments(parser)
args = parser.parse_args()

with open_bridge(args.address) as client:
    # 从这里开始才会 attach UAV；后面的 takeoff/move/land 会发送真实控制命令。
    vehicle = select_uav(client, args.entity)
    height = 1.0
    try:
        print("1) takeoff:", run_with_status("起飞中", lambda: vehicle.takeoff(height, timeout=30)))
        print(
            "2) forward:",
            run_with_status("前进中", lambda: vehicle.forward(speed_mps=0.15, duration_s=0.8, timeout=15)),
        )
        print(
            "3) backward:",
            run_with_status("后退中", lambda: vehicle.backward(speed_mps=0.15, duration_s=0.8, timeout=15)),
        )
        print(
            "4) left:",
            run_with_status("左移中", lambda: vehicle.left(speed_mps=0.15, duration_s=0.5, timeout=15)),
        )
        print(
            "5) right:",
            run_with_status("右移中", lambda: vehicle.right(speed_mps=0.15, duration_s=0.5, timeout=15)),
        )
        print(
            "6) up:",
            run_with_status("上升中", lambda: vehicle.up(speed_mps=0.1, duration_s=0.5, timeout=15)),
        )
        print(
            "7) down:",
            run_with_status("下降中", lambda: vehicle.down(speed_mps=0.1, duration_s=0.5, timeout=15)),
        )
        target = vehicle.state.position
        print(
            "8) move_to:",
            run_with_status("移动中", lambda: vehicle.move_to(target.x + 0.3, target.y, height, timeout=60)),
        )
        print("9) hover:", run_with_status("悬停中", lambda: vehicle.hover(timeout=15)))
    finally:
        if not vehicle.state.landed:
            print("10) land:", run_with_status("降落中", lambda: vehicle.land(timeout=30)))

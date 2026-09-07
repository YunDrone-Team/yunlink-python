"""完整 UAV 基础控制：起飞、前后左右上下、目标移动、悬停、降落。"""

from __future__ import annotations

import os

from yunlink_python import connect, discover_and_connect

address = os.getenv("YUNLINK_ADDRESS")
client = connect(address) if address else discover_and_connect(timeout=1.5)
with client:
    vehicle = client.vehicle(os.getenv("YUNLINK_VEHICLE", "uav1"))
    height = 1.0
    try:
        print("1) takeoff:", vehicle.takeoff(height, timeout=30))
        print("2) forward:", vehicle.forward(speed_mps=0.15, duration_s=0.8, timeout=15))
        print("3) backward:", vehicle.backward(speed_mps=0.15, duration_s=0.8, timeout=15))
        print("4) left:", vehicle.left(speed_mps=0.15, duration_s=0.5, timeout=15))
        print("5) right:", vehicle.right(speed_mps=0.15, duration_s=0.5, timeout=15))
        print("6) up:", vehicle.up(speed_mps=0.1, duration_s=0.5, timeout=15))
        print("7) down:", vehicle.down(speed_mps=0.1, duration_s=0.5, timeout=15))
        target = vehicle.state.position
        print("8) move_to:", vehicle.move_to(target.x + 0.3, target.y, height, timeout=60))
        print("9) hover:", vehicle.hover(timeout=15))
    finally:
        if not vehicle.state.landed:
            print("10) land:", vehicle.land(timeout=30))

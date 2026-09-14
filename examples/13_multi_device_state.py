"""只读监控所有 UAV/UGV 的状态，不发送控制动作。"""

from __future__ import annotations

import argparse
import time

from _session import open_bridge

from yunlink_python.display import format_table

parser = argparse.ArgumentParser(description="Watch every discovered device")
parser.add_argument("--seconds", type=float, default=30.0)
args = parser.parse_args()

with open_bridge() as client:
    # 这是只读监控：先打印目录，再按每个明确 UID attach 并订阅状态。
    devices = [client.entity(item.uid) for item in client.entities()]
    if not devices:
        raise SystemExit("没有发现设备")
    started = time.monotonic()
    while time.monotonic() - started < args.seconds:
        print("---")
        rows = []
        for device in devices:
            state = device.state
            position = state.position
            rows.append(
                {
                    "uid": device.uid,
                    "connected": "yes" if state.connected else "no",
                    "fresh": "yes" if state.is_fresh() else "no",
                    "x": f"{position.x:.2f}",
                    "y": f"{position.y:.2f}",
                    "z": f"{position.z:.2f}",
                }
            )
        print(
            format_table(
                rows,
                (
                    ("uid", "entity_uid"),
                    ("connected", "connected"),
                    ("fresh", "fresh"),
                    ("x", "x"),
                    ("y", "y"),
                    ("z", "z"),
                ),
            )
        )
        time.sleep(1.0)

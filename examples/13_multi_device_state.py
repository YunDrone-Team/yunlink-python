"""只读监控所有 UAV/UGV 的状态，不发送控制动作。"""

from __future__ import annotations

import argparse
import os
import time

from _session import print_device_catalog

from yunlink_python import connect, discover_and_connect

parser = argparse.ArgumentParser(description="Watch every discovered device")
parser.add_argument("--seconds", type=float, default=30.0)
args = parser.parse_args()

address = os.getenv("YUNLINK_ADDRESS")
client = connect(address) if address else discover_and_connect(timeout=1.5)
with client:
    # 这是只读监控：先打印目录，再按每个明确 UID attach 并订阅状态。
    print_device_catalog(client)
    devices = [client.entity(item.uid) for item in client.entities()]
    if not devices:
        raise SystemExit("没有发现设备")
    started = time.monotonic()
    while time.monotonic() - started < args.seconds:
        print("---")
        for device in devices:
            state = device.state
            print(
                f"{device.uid:24} connected={state.connected} fresh={state.is_fresh()} "
                f"pos=({state.position.x:.2f}, {state.position.y:.2f}, {state.position.z:.2f})"
            )
        time.sleep(1.0)

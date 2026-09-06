"""连接 Bridge，列出实体并读取第一份 UAV 状态。"""

from __future__ import annotations

import os
import time

from yunlink_sunray import connect, discover_and_connect


def open_client():
    address = os.getenv("YUNLINK_ADDRESS")
    return connect(address) if address else discover_and_connect(timeout=1.5)


with open_client() as client:
    print(f"Bridge endpoint: {client.raw.endpoint_uid}")
    print("All entities:")
    for entity in client.entities():
        print(f"  {entity.name} -> {entity.uid} ({entity.kind})")

    uavs = client.vehicles()
    if not uavs:
        raise SystemExit("没有发现 Sunray UAV")
    vehicle = client.vehicle(os.getenv("YUNLINK_VEHICLE", uavs[0].name))
    print(f"Selected UAV: {vehicle.uid}")
    deadline = time.monotonic() + 5.0
    while not vehicle.state.frame_id and time.monotonic() < deadline:
        time.sleep(0.05)
    print("Initial state:", vehicle.state)
    print("Raw YunLink transport:", type(client.raw).__name__)

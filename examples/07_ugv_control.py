"""读取无人车状态，执行 MovePoint、速度租约和 Hold。"""

from __future__ import annotations

import os

from yunlink_python import connect, discover_and_connect

address = os.getenv("YUNLINK_ADDRESS")
client = connect(address) if address else discover_and_connect(timeout=1.5)
with client:
    ugvs = client.ugvs()
    if not ugvs:
        raise SystemExit("没有发现 Sunray UGV")
    ugv = client.ugv(os.getenv("YUNLINK_UGV", ugvs[0].name))
    print("initial:", ugv.state)
    start = ugv.state.position
    print("move_to:", ugv.move_to(start.x + 0.3, start.y, timeout=45))
    print("velocity:", ugv.velocity(0.1, duration_s=0.5, timeout=15))
    print("hold:", ugv.hold(timeout=15))
    print("final:", ugv.state)

"""读取无人车状态，执行 MovePoint、速度租约和 Hold。"""

from __future__ import annotations

import argparse
import time

from _session import add_connection_arguments, open_bridge, select_ugv

from yunlink_python import run_with_status

parser = argparse.ArgumentParser(description="执行 UGV MovePoint、速度租约和 Hold")
add_connection_arguments(parser, entity_key="YUNLINK_UGV")
args = parser.parse_args()

with open_bridge(args.address) as client:
    # 这里使用明确的 UGV entity_uid；不会从目录中自动挑选第一台无人车。
    ugv = select_ugv(client, args.entity)
    deadline = time.monotonic() + 5.0
    while time.monotonic() < deadline and not (ugv.state.is_fresh() and ugv.state.frame_id):
        time.sleep(0.1)
    print("initial:", ugv.state)
    start = ugv.state.position
    print(
        "move_to:",
        run_with_status("移动中", lambda: ugv.move_to(start.x + 0.3, start.y, timeout=45)),
    )
    print(
        "velocity:",
        run_with_status("速度控制中", lambda: ugv.velocity(0.1, duration_s=0.5, timeout=15)),
    )
    print("hold:", run_with_status("保持中", lambda: ugv.hold(timeout=15)))
    print("final:", ugv.state)

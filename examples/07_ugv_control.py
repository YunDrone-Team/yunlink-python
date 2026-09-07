"""读取无人车状态，执行 MovePoint、速度租约和 Hold。"""

from __future__ import annotations

import argparse

from _session import add_connection_arguments, open_bridge, select_ugv

parser = argparse.ArgumentParser(description="执行 UGV MovePoint、速度租约和 Hold")
add_connection_arguments(parser, entity_env="YUNLINK_UGV")
args = parser.parse_args()

with open_bridge(args.address) as client:
    # 这里使用明确的 UGV entity_uid；不会从目录中自动挑选第一台无人车。
    ugv = select_ugv(client, args.entity)
    print("initial:", ugv.state)
    start = ugv.state.position
    print("move_to:", ugv.move_to(start.x + 0.3, start.y, timeout=45))
    print("velocity:", ugv.velocity(0.1, duration_s=0.5, timeout=15))
    print("hold:", ugv.hold(timeout=15))
    print("final:", ugv.state)

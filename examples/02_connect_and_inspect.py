"""连接 Bridge，只打印实时设备目录，不 attach 或控制设备。"""

from __future__ import annotations

import argparse

from _session import add_connection_arguments, open_bridge

parser = argparse.ArgumentParser(description="连接 Bridge 并打印设备目录，不控制设备")
add_connection_arguments(parser, include_entity=False)
args = parser.parse_args()

# 这里建立的只是 Bridge Session。client.entities() 只读目录，不会 attach 任何 UAV/UGV。
with open_bridge(args.address) as client:
    print("目录检查完成。下一步请从上面的 entity_uid 中选择设备，再运行 03_watch_state.py。")

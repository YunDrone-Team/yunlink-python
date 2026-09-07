"""搜索全部 Bridge，按 endpoint_uid 选择一个，再列出其设备目录。"""

from __future__ import annotations

import argparse
import os

from yunlink_python import connect_discovered, discover

parser = argparse.ArgumentParser(description="Discover Bridges and connect by endpoint ID")
parser.add_argument("--id", dest="endpoint_id", help="要连接的 Bridge endpoint_uid")
parser.add_argument("--entity", dest="entity_id", help="连接后选择的 UAV/UGV entity_uid 或显示名")
parser.add_argument("--timeout", type=float, default=1.5, help="搜索等待时间，单位秒")
args = parser.parse_args()

bridges = discover(timeout=args.timeout)
if not bridges:
    raise SystemExit("没有搜索到 Bridge，请检查网络或 discovery 端口")

print(f"搜索到 {len(bridges)} 个 Bridge：")
for index, bridge in enumerate(bridges, 1):
    entities = (
        ", ".join(
            f"{item.display_name or item.entity_uid} [{item.kind}]" for item in bridge.entities
        )
        or "无实体"
    )
    # 序号只用于阅读输出；真正的选择必须使用稳定的 endpoint_uid。
    print(f"[{index}] endpoint_uid={bridge.endpoint_uid}")
    print(f"    name={bridge.display_name or '-'} address={bridge.ip}:{bridge.tcp_port}")
    print(f"    entities={entities}")

selected_id = args.endpoint_id or os.getenv("YUNLINK_BRIDGE_ID")
if not selected_id:
    raise SystemExit(
        "请从上面的 endpoint_uid 中选择目标 Bridge，再使用 --id <endpoint_uid> 重新运行。"
    )

selected = next((item for item in bridges if item.endpoint_uid == selected_id), None)
if selected is None:
    raise SystemExit(f"未找到 Bridge endpoint_uid: {selected_id}")

print(f"正在连接 Bridge {selected.endpoint_uid} ({selected.ip}:{selected.tcp_port})")
with connect_discovered(selected) as client:
    print("连接成功，设备目录：")
    for entity in client.entities():
        print(f"  id={entity.uid} name={entity.name} kind={entity.kind}")
        print(f"    attributes={entity.attributes}")
        print(f"    capabilities={entity.capabilities}")
    entity_id = args.entity_id or os.getenv("YUNLINK_ENTITY_ID")
    if entity_id:
        device = client.entity(entity_id)
        print(f"Selected entity: id={device.uid} kind={type(device).__name__}")
        print(f"State: {device.state}")
    else:
        print(
            "尚未 attach 任何设备；请从上面的 entity_uid 中选择，再用 --entity <entity_uid> 重新运行。"
        )

"""搜索全部 Bridge，按 endpoint_uid 选择一个，再列出其设备目录。"""

from __future__ import annotations

import argparse

from _session import discover_timeout, example_value, wait_for_bridges

from yunlink_python import (
    connect_discovered,
    print_client_catalog,
    print_discovered_bridges,
    run_with_status,
)

parser = argparse.ArgumentParser(description="Discover Bridges and connect by endpoint ID")
parser.add_argument(
    "--id",
    dest="endpoint_id",
    default=example_value("YUNLINK_BRIDGE_ID"),
    help="要连接的 Bridge endpoint_uid；默认读 examples/yunlink.env",
)
parser.add_argument(
    "--entity",
    dest="entity_id",
    default=example_value("YUNLINK_UAV"),
    help="连接后选择的 UAV/UGV；默认读 examples/yunlink.env",
)
parser.add_argument(
    "--timeout",
    type=float,
    default=discover_timeout(),
    help="监听秒数，默认 5；也可在 examples/yunlink.env 写 YUNLINK_DISCOVER_TIMEOUT",
)
args = parser.parse_args()
if args.timeout <= 0:
    raise SystemExit("--timeout 必须大于 0")

bridges = wait_for_bridges(args.timeout)
if not bridges:
    raise SystemExit("没有搜索到 Bridge，请检查网络或 discovery 端口")

# 序号不是连接标识。选择 Bridge 用探测候选 ID / endpoint_uid，选择设备用 entity_uid。
print_discovered_bridges(bridges)

selected_id = args.endpoint_id
if not selected_id:
    raise SystemExit(
        "请从上面选择目标 Bridge，在 examples/yunlink.env 填写 YUNLINK_BRIDGE_ID，"
        "或使用 --id <endpoint_uid> 重新运行。"
    )

selected = next((item for item in bridges if item.endpoint_uid == selected_id), None)
if selected is None:
    raise SystemExit(f"未找到 Bridge endpoint_uid: {selected_id}")

print(f"正在连接 Bridge {selected.endpoint_uid} ({selected.ip}:{selected.tcp_port})")
client = run_with_status(
    f"正在连接 {selected.ip}:{selected.tcp_port}",
    lambda: connect_discovered(selected),
)
with client:
    print_client_catalog(client)
    entity_id = args.entity_id
    if entity_id:
        device = client.entity(entity_id)
        print(f"Selected entity: id={device.uid} kind={type(device).__name__}")
        print(f"State: {device.state}")
    else:
        print(
            "尚未 attach 任何设备；请在 examples/yunlink.env 填写 YUNLINK_UAV，"
            "或用 --entity <entity_uid> 重新运行。"
        )

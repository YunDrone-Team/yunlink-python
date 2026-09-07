"""搜索 YunLink Bridge，只读，不连接也不发送控制命令。"""

from yunlink_python import discover

# discovery 只搜索 Bridge，不会建立控制连接，也不会改变任何设备状态。
bridges = discover(timeout=1.5)
if not bridges:
    raise SystemExit("没有搜索到 Bridge；请检查网络，或直接设置 YUNLINK_ADDRESS")

for bridge in bridges:
    # endpoint_uid 是 Bridge 的稳定 ID；下面的 entity_uid 才是设备 ID。
    print(f"Bridge: {bridge.endpoint_uid}")
    print(f"  address: {bridge.ip}:{bridge.tcp_port}")
    print(f"  profiles: {bridge.profiles}")
    for entity in bridge.entities:
        print(f"  entity: {entity.entity_uid} | {entity.display_name} | {entity.kind}")
        print(f"    attributes: {entity.attributes}")

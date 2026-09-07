"""示例程序共用的 Bridge 连接和显式设备选择辅助函数。

这里故意把“连接 Bridge”和“attach 设备”分成两个步骤，避免入门示例
在用户还没有看过设备目录时就默认控制第一台无人机。
"""

from __future__ import annotations

import argparse
import os

from yunlink_python import Client, connect, discover_and_connect


def add_connection_arguments(
    parser: argparse.ArgumentParser, *, entity_env: str = "YUNLINK_VEHICLE"
) -> None:
    """给示例添加统一的 Bridge 地址和设备 ID 参数。"""
    parser.add_argument(
        "--address",
        default=os.getenv("YUNLINK_ADDRESS"),
        help="Bridge 地址，例如 192.168.31.236:9696；也可用 YUNLINK_ADDRESS",
    )
    parser.add_argument(
        "--entity",
        default=os.getenv(entity_env),
        help=f"明确的 entity_uid 或设备名称；也可用 {entity_env}",
    )


def open_bridge(address: str | None, *, auto_reconnect: bool = True) -> Client:
    """连接 Bridge 并打印目录；此函数不会 attach 或控制设备。"""
    client = (
        connect(address, auto_reconnect=auto_reconnect)
        if address
        else discover_and_connect(timeout=1.5, auto_reconnect=auto_reconnect)
    )
    print(f"已连接 Bridge: endpoint_uid={client.bridge_uid}")
    print_device_catalog(client)
    return client


def print_device_catalog(client: Client) -> list:
    """打印 Bridge 的实时设备目录并返回目录快照。"""
    devices = client.entities()
    print(f"设备目录（共 {len(devices)} 个）：")
    for device in devices:
        print(f"  entity_uid={device.uid}")
        print(f"    name={device.name} kind={device.kind}")
        print(f"    attributes={device.attributes}")
        print(f"    capabilities={device.capabilities}")
    return devices


def require_entity_id(requested: str | None, *, kind: str, env_name: str) -> str:
    """要求调用者提供明确设备 ID，不自动选择第一台设备。"""
    if requested:
        return requested
    raise SystemExit(
        f"请先查看上面的设备目录，再通过 --entity <entity_uid> 或 {env_name} 指定 {kind}。"
    )


def select_uav(client: Client, requested: str | None):
    """按明确 ID/名称 attach UAV；不会默认使用 uav1 或第一台 UAV。"""
    return client.vehicle(require_entity_id(requested, kind="UAV", env_name="YUNLINK_VEHICLE"))


def select_ugv(client: Client, requested: str | None):
    """按明确 ID/名称 attach UGV；不会默认使用 ugv1 或第一台 UGV。"""
    return client.ugv(require_entity_id(requested, kind="UGV", env_name="YUNLINK_UGV"))

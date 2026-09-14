"""示例程序共用的目标配置、Bridge 连接和显式设备选择。

目标机器写在 ``examples/yunlink.env``，不要每次 export。
命令行 ``--address`` / ``--entity`` 只用于临时覆盖。
连接 Bridge 和 attach 设备仍然分成两步，避免还没看目录就控制第一台无人机。
"""

from __future__ import annotations

import argparse
from functools import lru_cache
from pathlib import Path

from yunlink_python import (
    Client,
    connect,
    connect_discovered,
    discover,
    print_client_catalog,
    run_with_status,
)

ENV_FILE = Path(__file__).resolve().with_name("yunlink.env")


def parse_env_file(text: str) -> dict[str, str]:
    values: dict[str, str] = {}
    for raw in text.splitlines():
        line = raw.strip()
        if not line or line.startswith("#"):
            continue
        if line.startswith("export "):
            line = line[7:].strip()
        if "=" not in line:
            continue
        key, value = line.split("=", 1)
        key = key.strip()
        value = value.strip().strip("'").strip('"')
        if key:
            values[key] = value
    return values


@lru_cache(maxsize=1)
def load_example_config() -> dict[str, str]:
    if not ENV_FILE.is_file():
        return {}
    return parse_env_file(ENV_FILE.read_text(encoding="utf-8"))


def example_value(*keys: str, default: str | None = None) -> str | None:
    config = load_example_config()
    for key in keys:
        value = config.get(key)
        if value:
            return value
    return default


def env_file_hint() -> str:
    return "examples/yunlink.env（可先复制 yunlink.env.example）"


def discover_timeout(default: float = 5.0) -> float:
    raw = example_value("YUNLINK_DISCOVER_TIMEOUT")
    if not raw:
        return default
    try:
        value = float(raw)
    except ValueError:
        return default
    return value if value > 0 else default


def wait_for_bridges(timeout: float | None = None) -> list:
    seconds = discover_timeout() if timeout is None else timeout
    extras = []
    address = example_value("YUNLINK_ADDRESS")
    if address:
        extras.append(address)
    return run_with_status(
        f"正在搜索 Bridge，监听 {seconds:g} 秒",
        lambda: discover(timeout=seconds, extra_hosts=extras),
    )


def add_connection_arguments(
    parser: argparse.ArgumentParser,
    *,
    entity_key: str = "YUNLINK_UAV",
    include_entity: bool = True,
) -> None:
    """给示例添加统一的 Bridge 地址和设备 ID 参数。"""
    parser.add_argument(
        "--address",
        default=example_value("YUNLINK_ADDRESS"),
        help=f"临时覆盖 Bridge 地址；默认读 {env_file_hint()}",
    )
    if include_entity:
        parser.add_argument(
            "--entity",
            default=example_value(entity_key),
            help=f"临时覆盖 entity_uid；默认读 {env_file_hint()} 中的 {entity_key}",
        )


def open_bridge(address: str | None = None, *, auto_reconnect: bool = True) -> Client:
    """连接 Bridge 并打印目录；此函数不会 attach 或控制设备。"""
    target = address if address else example_value("YUNLINK_ADDRESS")
    if target:
        client = run_with_status(
            f"正在连接 {target}",
            lambda: connect(target, auto_reconnect=auto_reconnect),
        )
    else:
        bridges = wait_for_bridges()
        if not bridges:
            raise SystemExit(
                "没有搜索到 Bridge；请检查网络，或在 examples/yunlink.env 填写 YUNLINK_ADDRESS。"
            )
        if len(bridges) > 1:
            raise SystemExit(
                "搜索到多个 Bridge，请在 examples/yunlink.env 填写 YUNLINK_ADDRESS 或 YUNLINK_BRIDGE_ID。"
            )
        client = run_with_status(
            f"正在连接 {bridges[0].ip}:{bridges[0].tcp_port}",
            lambda: connect_discovered(bridges[0], auto_reconnect=auto_reconnect),
        )
    print_device_catalog(client)
    return client


def print_device_catalog(client: Client) -> list:
    """打印 Bridge 的实时设备目录并返回目录快照。"""
    return print_client_catalog(client)


def require_entity_id(requested: str | None, *, kind: str, key: str) -> str:
    """要求调用者提供明确设备 ID，不自动选择第一台设备。"""
    if requested:
        return requested
    raise SystemExit(
        f"请先查看上面的设备目录，再在 {env_file_hint()} 填写 {key}，"
        f"或用 --entity <entity_uid> 指定 {kind}。"
    )


def select_uav(client: Client, requested: str | None):
    """按明确 ID/名称 attach UAV；不会默认使用 uav1 或第一台 UAV。"""
    return client.vehicle(require_entity_id(requested, kind="UAV", key="YUNLINK_UAV"))


def select_ugv(client: Client, requested: str | None):
    """按明确 ID/名称 attach UGV；不会默认使用 ugv1 或第一台 UGV。"""
    return client.ugv(require_entity_id(requested, kind="UGV", key="YUNLINK_UGV"))

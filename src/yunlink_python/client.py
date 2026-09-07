"""Connection and vehicle selection for the public SDK."""

from __future__ import annotations

import dataclasses
import ipaddress

import yunlink

from .errors import ConnectionError, EntityNotFoundError
from .transport import Transport

DEFAULT_TCP_PORT = 9696
DEFAULT_DISCOVERY_PORT = 9697


@dataclasses.dataclass(frozen=True)
class EntityInfo:
    uid: str
    name: str
    kind: str
    attributes: dict[str, str]
    capabilities: tuple[str, ...]


VehicleInfo = EntityInfo


def _parse_address(address: str, default_port: int = DEFAULT_TCP_PORT) -> tuple[str, int]:
    value = address.strip()
    if not value:
        raise ValueError("address must not be empty")
    if value.startswith("["):
        close = value.find("]")
        if close < 0:
            raise ValueError(f"invalid address: {address}")
        host = value[1:close]
        suffix = value[close + 1 :]
        port = default_port if not suffix else int(suffix.removeprefix(":"))
        return host, _validate_port(port)
    if value.count(":") == 1:
        host, raw_port = value.rsplit(":", 1)
        return host, _validate_port(int(raw_port))
    if value.count(":") > 1:
        ipaddress.IPv6Address(value)
    return value, default_port


def _validate_port(port: int) -> int:
    if not 1 <= port <= 65535:
        raise ValueError("port must be between 1 and 65535")
    return port


class Client:
    """已连接到一个 YunLink Bridge 的客户端。

    创建 Client 只建立 Bridge Session，不会自动选择、attach 或控制任何设备。
    先调用 :meth:`entities` 查看目录，再把明确的 entity UID 或设备名称传给
    :meth:`vehicle`、:meth:`ugv` 或 :meth:`entity`。
    """

    def __init__(
        self,
        address: str,
        *,
        shared_secret: str = "yunlink-default-secret",
        auto_reconnect: bool = True,
    ) -> None:
        host, port = _parse_address(address)
        self._transport = Transport(host, port, shared_secret, auto_reconnect)
        self._entities: dict[str, object] = {}

    @property
    def raw(self) -> Transport:
        """返回底层 Transport，仅供需要 YunLink 原始能力的高级用户使用。"""
        return self._transport

    @property
    def bridge_uid(self) -> str:
        """返回当前连接的远端 Bridge ``endpoint_uid``。"""
        return self._transport.endpoint_uid

    def entities(self) -> list[EntityInfo]:
        """读取 Bridge 的实时设备目录，不 attach 设备，也不申请控制权限。"""
        return [
            EntityInfo(
                entity.entity_uid,
                entity.display_name or entity.entity_uid,
                entity.kind,
                dict(entity.attributes),
                entity.capabilities,
            )
            for entity in self._transport.directory().entities
        ]

    def vehicles(self) -> list[EntityInfo]:
        return [item for item in self.entities() if item.kind == "sunray.uav"]

    def ugvs(self) -> list[EntityInfo]:
        return [item for item in self.entities() if item.kind == "sunray.ugv"]

    def vehicle(self, uid: str | None = None):
        """按明确的 UAV UID 或名称 attach 一个 UAV 并订阅其状态。

        多台 UAV 同时存在时必须显式传入 ``uid``，不会默认选择第一台设备。
        """
        from .vehicle import Vehicle

        available = self.vehicles()
        if uid is None:
            if len(available) != 1:
                detail = (
                    "no Sunray UAV was found"
                    if not available
                    else "multiple UAVs found; specify uid"
                )
                raise EntityNotFoundError(detail)
            uid = available[0].uid
        else:
            uid = self._resolve_entity_id(available, uid, "Sunray UAV")
        if uid not in self._entities:
            self._entities[uid] = Vehicle(self._transport, uid)
        return self._entities[uid]

    def ugv(self, uid: str | None = None):
        """按明确的 UGV UID 或名称 attach 一个 UGV 并订阅其状态。"""
        from .ugv import Ugv

        available = self.ugvs()
        if uid is None:
            if len(available) != 1:
                detail = (
                    "no Sunray UGV was found"
                    if not available
                    else "multiple UGVs found; specify uid"
                )
                raise EntityNotFoundError(detail)
            uid = available[0].uid
        else:
            uid = self._resolve_entity_id(available, uid, "Sunray UGV")
        if uid not in self._entities:
            self._entities[uid] = Ugv(self._transport, uid)
        return self._entities[uid]

    def entity(self, uid: str):
        """按 UID 或名称选择并 attach 一个已列出的 UAV 或 UGV。"""
        info = next((item for item in self.entities() if item.uid == uid), None)
        if info is None:
            matches = [item for item in self.entities() if item.name == uid]
            if len(matches) == 1:
                info = matches[0]
        if info is None:
            raise EntityNotFoundError(f"entity not found: {uid}")
        return self.vehicle(uid) if info.kind == "sunray.uav" else self.ugv(uid)

    @staticmethod
    def _resolve_entity_id(items: list[EntityInfo], identifier: str, label: str) -> str:
        matches = [item for item in items if item.uid == identifier or item.name == identifier]
        if not matches:
            raise EntityNotFoundError(f"{label} not found: {identifier}")
        if len(matches) > 1:
            raise EntityNotFoundError(f"{label} name is ambiguous: {identifier}")
        return matches[0].uid

    def close(self) -> None:
        self._transport.close()

    def __enter__(self) -> Client:  # noqa: PYI034 - Python 3.10 has no typing.Self
        return self

    def __exit__(self, *_args: object) -> None:
        self.close()


def connect(
    address: str,
    *,
    shared_secret: str = "yunlink-default-secret",
    auto_reconnect: bool = True,
) -> Client:
    """连接 YunLink Bridge；不会自动选择或 attach 任何设备。"""
    return Client(address, shared_secret=shared_secret, auto_reconnect=auto_reconnect)


def connect_discovered(
    bridge: yunlink.Advertisement,
    *,
    shared_secret: str = "yunlink-default-secret",
    auto_reconnect: bool = True,
) -> Client:
    """Connect to one advertisement returned by :func:`discover`.

    The advertisement's ``endpoint_uid`` is the stable Bridge selection ID;
    callers do not need to reconstruct an address from the discovery result.
    """
    host = bridge.ip
    address = f"[{host}]:{bridge.tcp_port}" if ":" in host else f"{host}:{bridge.tcp_port}"
    return connect(address, shared_secret=shared_secret, auto_reconnect=auto_reconnect)


def discover(
    *,
    host: str = "255.255.255.255",
    port: int = DEFAULT_DISCOVERY_PORT,
    timeout: float = 1.0,
    shared_secret: str = "yunlink-default-secret",
) -> list[yunlink.Advertisement]:
    return yunlink.discover(host=host, port=port, timeout=timeout, shared_secret=shared_secret)


def discover_and_connect(
    *,
    host: str = "255.255.255.255",
    port: int = DEFAULT_DISCOVERY_PORT,
    timeout: float = 1.0,
    shared_secret: str = "yunlink-default-secret",
    auto_reconnect: bool = True,
) -> Client:
    bridges = discover(host=host, port=port, timeout=timeout, shared_secret=shared_secret)
    if not bridges:
        raise ConnectionError("no YunLink Bridge was discovered")
    if len(bridges) > 1:
        endpoints = ", ".join(item.endpoint_uid for item in bridges)
        raise ConnectionError(
            f"multiple YunLink Bridges discovered: {endpoints}; use connect(address)"
        )
    bridge = bridges[0]
    return connect_discovered(bridge, shared_secret=shared_secret, auto_reconnect=auto_reconnect)

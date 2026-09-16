"""UDP discovery that still works when Wi-Fi drops limited broadcasts."""

from __future__ import annotations

import ipaddress
import secrets
import socket
import time
from collections.abc import Iterable, Sequence

from yunlink.discovery import Advertisement, _configure, _decode, _query, encoded, library

DEFAULT_DISCOVERY_PORT = 9697
DEFAULT_DISCOVERY_TIMEOUT = 5.0
_LIMITED_BROADCAST = "255.255.255.255"


def discover(
    *,
    host: str = _LIMITED_BROADCAST,
    port: int = DEFAULT_DISCOVERY_PORT,
    timeout: float = DEFAULT_DISCOVERY_TIMEOUT,
    shared_secret: str = "yunlink-default-secret",
    extra_hosts: Sequence[str] = (),
) -> list[Advertisement]:
    """Listen until ``timeout``, then return unique Bridge advertisements.

    Wi-Fi often drops ``255.255.255.255``. This sends the same authenticated query to:

    - the requested ``host``
    - any ``extra_hosts`` (for example a known Bridge IP)
    - each local IPv4 interface broadcast
    - every other address in the local /24, when the interface is a /24
    """
    if timeout <= 0:
        raise ValueError("timeout must be greater than 0")
    lib = library()
    _configure(lib)
    nonce = secrets.randbits(64) or 1
    window_ms = max(1, min(65535, int(timeout * 1000)))
    secret = encoded(shared_secret)
    request = _query(lib, nonce, window_ms, secret)
    targets = _discovery_targets(host, extra_hosts)
    found: dict[str, Advertisement] = {}
    with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as udp:
        udp.setsockopt(socket.SOL_SOCKET, socket.SO_BROADCAST, 1)
        udp.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        udp.bind(("", 0))
        udp.settimeout(0.05)
        deadline = time.monotonic() + timeout
        next_burst = 0.0
        while True:
            now = time.monotonic()
            remaining = deadline - now
            if remaining <= 0:
                break
            if now >= next_burst:
                _send_query(udp, request, port, targets)
                next_burst = now + 0.4
            try:
                payload, sender = udp.recvfrom(8192)
            except TimeoutError:
                continue
            except (ConnectionResetError, ConnectionRefusedError, OSError):
                # Windows surfaces ICMP Port Unreachable from /24 probes as
                # WinError 10054 on the next recvfrom. Ignore and keep listening.
                continue
            advertisement = _decode(lib, payload, secret, nonce, sender[0])
            if advertisement is not None:
                found[advertisement.endpoint_uid] = advertisement
    return list(found.values())


def _discovery_targets(host: str, extra_hosts: Sequence[str]) -> tuple[str, ...]:
    targets: list[str] = []
    seen: set[str] = set()

    def add(value: str) -> None:
        ip = value.strip().strip("[]")
        if not ip or ip in seen:
            return
        seen.add(ip)
        targets.append(ip)

    add(host)
    for item in extra_hosts:
        add(_host_from_address(item))
    for local_ip in _local_ipv4_addrs():
        add(str(ipaddress.ip_interface(f"{local_ip}/24").network.broadcast_address))
        for peer in _subnet24_hosts(local_ip):
            add(peer)
    if _LIMITED_BROADCAST not in seen:
        add(_LIMITED_BROADCAST)
    return tuple(targets)


def _send_query(udp: socket.socket, request: bytes, port: int, targets: Iterable[str]) -> None:
    for ip in targets:
        try:
            udp.sendto(request, (ip, port))
        except OSError:
            continue


def _host_from_address(address: str) -> str:
    value = address.strip()
    if value.startswith("["):
        close = value.find("]")
        return value[1:close] if close > 0 else value
    if value.count(":") == 1:
        return value.rsplit(":", 1)[0]
    return value


def _local_ipv4_addrs() -> list[str]:
    addrs: set[str] = set()
    probe = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        probe.connect(("8.8.8.8", 80))
        addrs.add(probe.getsockname()[0])
    except OSError:
        pass
    finally:
        probe.close()
    try:
        for info in socket.getaddrinfo(socket.gethostname(), None, socket.AF_INET):
            addrs.add(info[4][0])
    except OSError:
        pass
    return [item for item in sorted(addrs) if not item.startswith("127.")]


def _subnet24_hosts(local_ip: str) -> list[str]:
    try:
        address = ipaddress.IPv4Address(local_ip)
    except ipaddress.AddressValueError:
        return []
    if address.is_loopback or address.is_link_local:
        return []
    network = ipaddress.ip_network(f"{address}/24", strict=False)
    return [str(item) for item in network.hosts() if item != address]

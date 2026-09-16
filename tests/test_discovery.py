import inspect

from yunlink_python.discovery import (
    _discovery_targets,
    _host_from_address,
    _subnet24_hosts,
    discover,
)


def test_host_from_address_strips_port_and_brackets():
    assert _host_from_address("192.168.31.236:9696") == "192.168.31.236"
    assert _host_from_address("[2001:db8::1]:9696") == "2001:db8::1"
    assert _host_from_address("192.168.31.236") == "192.168.31.236"


def test_subnet24_hosts_excludes_self_and_covers_peers():
    hosts = _subnet24_hosts("192.168.31.170")
    assert "192.168.31.170" not in hosts
    assert "192.168.31.236" in hosts
    assert "192.168.31.1" in hosts
    assert len(hosts) == 253


def test_discover_swallows_windows_connection_reset():
    source = inspect.getsource(discover)
    assert "ConnectionResetError" in source


def test_discovery_targets_include_known_bridge_and_broadcast():
    targets = _discovery_targets("255.255.255.255", ["192.168.31.236:9696"])
    assert "255.255.255.255" in targets
    assert "192.168.31.236" in targets

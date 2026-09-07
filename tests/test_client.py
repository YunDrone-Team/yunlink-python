from types import SimpleNamespace

import pytest
from conftest import FakeBridge

from yunlink_python import connect, connect_discovered
from yunlink_python.client import _parse_address


@pytest.mark.parametrize(
    ("address", "expected"),
    [
        ("192.168.31.236", ("192.168.31.236", 9696)),
        ("192.168.31.236:9700", ("192.168.31.236", 9700)),
        ("[::1]:9700", ("::1", 9700)),
    ],
)
def test_parse_address(address, expected):
    assert _parse_address(address) == expected


def test_parse_address_rejects_invalid_port():
    with pytest.raises(ValueError):
        _parse_address("127.0.0.1:70000")


def test_connect_discovered_uses_selected_advertisement(monkeypatch):
    calls = []

    def fake_connect(address, **kwargs):
        calls.append((address, kwargs))
        return "client"

    monkeypatch.setattr("yunlink_python.client.connect", fake_connect)
    bridge = SimpleNamespace(ip="2001:db8::10", tcp_port=9696, endpoint_uid="bridge-10")
    assert connect_discovered(bridge, shared_secret="test", auto_reconnect=False) == "client"
    assert calls == [("[2001:db8::10]:9696", {"shared_secret": "test", "auto_reconnect": False})]


def test_vehicle_and_ugv_accept_display_names():
    bridge = FakeBridge()
    try:
        with connect(f"127.0.0.1:{bridge.port}") as client:
            assert client.vehicle("uav1").uid == "uav1"
            assert client.ugv("ugv1").uid == "ugv1"
    finally:
        bridge.close()

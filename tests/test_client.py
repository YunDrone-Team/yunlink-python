import pytest
from conftest import FakeBridge

from yunlink_sunray import connect
from yunlink_sunray.client import _parse_address


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


def test_vehicle_and_ugv_accept_display_names():
    bridge = FakeBridge()
    try:
        with connect(f"127.0.0.1:{bridge.port}") as client:
            assert client.vehicle("uav1").uid == "uav1"
            assert client.ugv("ugv1").uid == "ugv1"
    finally:
        bridge.close()

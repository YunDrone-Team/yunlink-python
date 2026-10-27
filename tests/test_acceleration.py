import time

import pytest
from conftest import FakeBridge
from yunlink.profiles.com.yundrone.sunray.v2 import sunray_pb2

from yunlink_python import ActionFailedError, DisconnectedError, connect
from yunlink_python.profiles import ACCELERATION_COMPENSATION, acceleration_compensation_payload


def test_payload_preserves_ned_and_rejects_nonfinite():
    goal = sunray_pb2.UavAccelerationCompensationGoal.FromString(
        acceleration_compensation_payload(0.1, -0.2, 0.05)
    )
    assert goal.acceleration_ned_mps2.x == 0.1
    assert goal.acceleration_ned_mps2.y == -0.2
    assert goal.acceleration_ned_mps2.z == 0.05
    assert ACCELERATION_COMPENSATION.minor == 20
    with pytest.raises(ValueError):
        acceleration_compensation_payload(float("nan"), 0, 0)


def test_samples_update_cancel_and_no_automatic_resend():
    bridge = FakeBridge()
    try:
        with connect(f"127.0.0.1:{bridge.port}") as client:
            vehicle = client.vehicle()
            with vehicle.acceleration_compensation() as channel:
                for _ in range(5):
                    channel.update(0.01, 0.02, -0.03)
                    time.sleep(0.01)
                vehicle.hover()  # Independent motion action must not replace the channel.
                assert not channel.action.done
            assert bridge.acceleration_samples == [(0, 0, 0)] + [(0.01, 0.02, -0.03)] * 5
            expired = vehicle.acceleration_compensation()
            with pytest.raises(ActionFailedError, match="input expired"):
                expired.action.wait(2)
            assert len(bridge.acceleration_samples) == 7
            with pytest.raises(ActionFailedError):
                expired.update(0, 0, 0)
    finally:
        bridge.close()


def test_disconnect_never_replays_compensation():
    bridge = FakeBridge()
    try:
        with connect(f"127.0.0.1:{bridge.port}") as client:
            channel = client.vehicle().acceleration_compensation()
            time.sleep(0.1)
            bridge.disconnect_clients()
            with pytest.raises(DisconnectedError):
                channel.action.wait(3)
            with pytest.raises(DisconnectedError):
                channel.update(0.1, 0, 0)
            assert len(bridge.acceleration_samples) == 1
    finally:
        bridge.close()

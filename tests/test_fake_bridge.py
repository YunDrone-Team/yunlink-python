import time

import pytest
from conftest import FakeBridge

from yunlink_sunray import ActionFailedError, DisconnectedError, Waypoint, connect


@pytest.fixture
def bridge():
    value = FakeBridge()
    try:
        yield value
    finally:
        value.close()


def test_complete_uav_control_flow_without_ros(bridge):
    with connect(f"127.0.0.1:{bridge.port}") as client:
        assert [item.uid for item in client.vehicles()] == ["uav1"]
        vehicle = client.vehicle()
        deadline = time.monotonic() + 2
        while not vehicle.state.frame_id and time.monotonic() < deadline:
            time.sleep(0.01)
        assert vehicle.state.frame_id == "world"
        vehicle.takeoff(1.5)
        vehicle.move_to(2.0, 0.0, 1.5)
        vehicle.waypoints([Waypoint(2.0, 0.0, 1.5), Waypoint(2.5, 0.5, 1.5)])
        vehicle.hover()
        vehicle.land()
        assert bridge.action_goals == [
            "TakeoffGoal",
            "UavWaypointMissionGoal",
            "UavWaypointMissionGoal",
            "HoverGoal",
            "LandGoal",
        ]


def test_action_rejection_is_public_error(bridge):
    bridge.reject_actions = True
    with (
        connect(f"127.0.0.1:{bridge.port}") as client,
        pytest.raises(ActionFailedError, match="rejected"),
    ):
        client.vehicle().takeoff()


def test_disconnect_fails_action_and_does_not_replay(bridge):
    bridge.hold_actions = True
    with connect(f"127.0.0.1:{bridge.port}") as client:
        handle = client.vehicle().takeoff(wait=False)
        deadline = time.monotonic() + 2
        while not bridge.action_goals and time.monotonic() < deadline:
            time.sleep(0.01)
        bridge.disconnect_clients()
        with pytest.raises(DisconnectedError):
            handle.wait(3)
        time.sleep(1.5)
        assert bridge.action_goals == ["TakeoffGoal"]


def test_cancel_stops_the_latest_pending_action(bridge):
    bridge.hold_actions = True
    with connect(f"127.0.0.1:{bridge.port}") as client:
        vehicle = client.vehicle()
        handle = vehicle.takeoff(wait=False)
        result = vehicle.cancel()
        assert result is not None
        assert result.phase.name == "CANCELLED"
        assert handle.done


def test_cancel_without_local_action_uses_planner_rpc(bridge):
    with connect(f"127.0.0.1:{bridge.port}") as client:
        result = client.vehicle().cancel()
        assert result.action_id == 0
        assert result.phase.name == "SUCCEEDED"


def test_direct_control_and_ugv_use_their_protocol_contract(bridge):
    with connect(f"127.0.0.1:{bridge.port}") as client:
        result = client.vehicle("uav1").forward(speed_mps=0.2, duration_s=0.2, fixed_height_m=1.0)
        assert result.phase.name == "SUCCEEDED"
        assert [item.uid for item in client.ugvs()] == ["ugv1"]
        assert client.ugv().state.frame_id == "world"

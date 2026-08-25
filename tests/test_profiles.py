import math

import pytest
from yunlink.profiles.com.yundrone.sunray.v2 import sunray_pb2

from yunlink_sunray.profiles import Waypoint, nav_payload, takeoff_payload, waypoint_payload


def test_navigation_payload_uses_profile_units():
    message = sunray_pb2.UavNavGoal.FromString(nav_payload(1.0, 2.0, 3.0, math.pi / 2, "world"))
    assert (message.position_m.x, message.position_m.y, message.position_m.z) == (1.0, 2.0, 3.0)
    assert message.yaw_rad == math.pi / 2
    assert message.frame_id == "world"


def test_waypoint_payload_is_hover_complete_mission():
    payload = waypoint_payload([Waypoint(1, 2, 1.5, 0.4, 1.0)], "world", "test")
    message = sunray_pb2.UavWaypointMissionGoal.FromString(payload)
    assert message.task_name == "test"
    assert message.completion_action == sunray_pb2.UAV_MISSION_FINISH_HOVER
    assert message.waypoints[0].arrival_action == sunray_pb2.UAV_WAYPOINT_HOLD_SET_YAW


@pytest.mark.parametrize("value", [float("nan"), float("inf"), float("-inf")])
def test_navigation_rejects_non_finite_coordinates(value):
    with pytest.raises(ValueError):
        nav_payload(value, 0, 1, 0, "world")


def test_takeoff_uses_profile_validation():
    with pytest.raises(ValueError):
        takeoff_payload(-1)

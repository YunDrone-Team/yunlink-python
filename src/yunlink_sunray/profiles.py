"""Sunray Profile constants and protobuf conversions."""

from __future__ import annotations

import math
from collections.abc import Sequence
from dataclasses import dataclass

import yunlink
from yunlink.profiles import (
    validate_land_goal,
    validate_takeoff_goal,
    validate_uav_nav_goal,
    validate_uav_waypoint_mission_goal,
)
from yunlink.profiles.com.yundrone.sunray.v2 import sunray_pb2
from yunlink.profiles.org.yunlink.mobility.v1 import mobility_pb2

MOBILITY = yunlink.Profile("org.yunlink.mobility", 1, 0, "mobility-v1")
TELEMETRY = yunlink.Profile("org.yunlink.telemetry", 1, 0, "telemetry-summary-v1")
SUNRAY = yunlink.Profile("com.yundrone.sunray", 2, 7, "sunray-v2.7")
OFFERED_PROFILES = (MOBILITY, TELEMETRY, SUNRAY)
REQUIRED_PROFILES = (MOBILITY, SUNRAY)


def type_ref(name: str, minor: int = 0) -> yunlink.TypeRef:
    return yunlink.TypeRef(SUNRAY.profile_id, SUNRAY.major, name, minor)


TAKEOFF = type_ref("TakeoffGoal")
LAND = type_ref("LandGoal")
HOVER = type_ref("HoverGoal")
NAV_GOAL = type_ref("UavNavGoal", 3)
WAYPOINT_MISSION = type_ref("UavWaypointMissionGoal", 2)


@dataclass(frozen=True)
class Waypoint:
    x: float
    y: float
    z: float
    yaw_rad: float = 0.0
    hold_time_s: float = 0.0


def finite(*values: float) -> None:
    if not all(math.isfinite(value) for value in values):
        raise ValueError("coordinates and flight parameters must be finite")


def takeoff_payload(height_m: float, max_velocity_mps: float = 0.0) -> bytes:
    message = sunray_pb2.TakeoffGoal(
        takeoff_relative_height_m=height_m,
        takeoff_max_velocity_mps=max_velocity_mps,
    )
    validate_takeoff_goal(message)
    return message.SerializeToString()


def land_payload(max_velocity_mps: float = 0.0) -> bytes:
    message = sunray_pb2.LandGoal(land_max_velocity_mps=max_velocity_mps)
    validate_land_goal(message)
    return message.SerializeToString()


def hover_payload() -> bytes:
    return sunray_pb2.HoverGoal().SerializeToString()


def nav_payload(x: float, y: float, z: float, yaw_rad: float, frame_id: str) -> bytes:
    finite(x, y, z, yaw_rad)
    if not frame_id:
        raise ValueError("frame_id must not be empty")
    message = sunray_pb2.UavNavGoal(
        frame_id=frame_id,
        position_m=mobility_pb2.Vector3(x=x, y=y, z=z),
        yaw_rad=yaw_rad,
    )
    validate_uav_nav_goal(message)
    return message.SerializeToString()


def waypoint_payload(
    waypoints: Sequence[Waypoint], frame_id: str, task_name: str = "Python waypoint mission"
) -> bytes:
    if not frame_id:
        raise ValueError("frame_id must not be empty")
    if not waypoints:
        raise ValueError("at least one waypoint is required")
    message = sunray_pb2.UavWaypointMissionGoal(
        frame_id=frame_id,
        task_name=task_name,
        completion_action=sunray_pb2.UAV_MISSION_FINISH_HOVER,
    )
    for item in waypoints:
        finite(item.x, item.y, item.z, item.yaw_rad, item.hold_time_s)
        if item.hold_time_s < 0:
            raise ValueError("waypoint hold_time_s must not be negative")
        target = message.waypoints.add()
        target.position_m.CopyFrom(mobility_pb2.Vector3(x=item.x, y=item.y, z=item.z))
        target.yaw_rad = item.yaw_rad
        target.hold_time_s = item.hold_time_s
        target.arrival_action = sunray_pb2.UAV_WAYPOINT_HOLD_SET_YAW
    validate_uav_waypoint_mission_goal(message)
    return message.SerializeToString()

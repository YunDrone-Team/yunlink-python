"""Sunray Profile constants and protobuf conversions."""

from __future__ import annotations

import math
from collections.abc import Sequence
from dataclasses import dataclass

import yunlink

from ._binding_compat import prepare_profile_imports

prepare_profile_imports()

from yunlink.profiles import (
    validate_emergency_kill_goal,
    validate_land_goal,
    validate_takeoff_goal,
    validate_uav_direct_control_goal,
    validate_uav_nav_goal,
    validate_uav_waypoint_mission_goal,
    validate_ugv_move_point_goal,
    validate_ugv_velocity_goal,
)
from yunlink.profiles.com.yundrone.sunray.v2 import sunray_pb2
from yunlink.profiles.org.yunlink.mobility.v1 import mobility_pb2

MOBILITY = yunlink.Profile("org.yunlink.mobility", 1, 0, "mobility-v1")
TELEMETRY = yunlink.Profile("org.yunlink.telemetry", 1, 0, "telemetry-summary-v1")
SUNRAY = yunlink.Profile("com.yundrone.sunray", 2, 8, "sunray-v2.8")
OFFERED_PROFILES = (MOBILITY, TELEMETRY, SUNRAY)
REQUIRED_PROFILES = (MOBILITY, SUNRAY)


def type_ref(name: str, minor: int = 0) -> yunlink.TypeRef:
    return yunlink.TypeRef(SUNRAY.profile_id, SUNRAY.major, name, minor)


TAKEOFF = type_ref("TakeoffGoal")
LAND = type_ref("LandGoal")
HOVER = type_ref("HoverGoal")
EMERGENCY_KILL = type_ref("EmergencyKillGoal")
RETURN_HOME = type_ref("UavReturnHomeGoal")
NAV_GOAL = type_ref("UavNavGoal", 3)
WAYPOINT_MISSION = type_ref("UavWaypointMissionGoal", 2)
UAV_DIRECT_CONTROL = type_ref("UavDirectControlGoal")
UGV_MOVE_POINT = type_ref("UgvMovePointGoal", 5)
UGV_VELOCITY = type_ref("UgvVelocityGoal", 5)
UGV_HOLD = type_ref("UgvHoldGoal", 5)
PLANNER_CANCEL = type_ref("PlannerCancelTaskRequest", 1)


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


def emergency_kill_payload(confirm: bool) -> bytes:
    message = sunray_pb2.EmergencyKillGoal(confirmed=bool(confirm))
    validate_emergency_kill_goal(message)
    return message.SerializeToString()


def return_home_payload() -> bytes:
    return sunray_pb2.UavReturnHomeGoal().SerializeToString()


def direct_world_position_payload(
    x: float,
    y: float,
    z: float,
    *,
    frame_id: str,
    yaw_rad: float = 0.0,
) -> bytes:
    finite(x, y, z, yaw_rad)
    if not frame_id:
        raise ValueError("frame_id must not be empty")
    message = sunray_pb2.UavDirectControlGoal(
        world_position=sunray_pb2.WorldPositionTarget(
            frame_id=frame_id,
            position_m=mobility_pb2.Vector3(x=x, y=y, z=z),
        ),
        yaw=sunray_pb2.YawTarget(mode=sunray_pb2.UAV_YAW_SET_ANGLE, value=yaw_rad),
        controller=sunray_pb2.UAV_CONTROLLER_DEFAULT,
    )
    validate_uav_direct_control_goal(message)
    return message.SerializeToString()


def direct_world_velocity_payload(
    vx: float,
    vy: float,
    vz: float = 0.0,
    *,
    frame_id: str,
    lease_ms: int = 1000,
    height_lock_m: float | None = None,
) -> bytes:
    finite(vx, vy, vz)
    if not frame_id:
        raise ValueError("frame_id must not be empty")
    if not 250 <= lease_ms <= 2000:
        raise ValueError("lease_ms must be between 250 and 2000")
    target = sunray_pb2.WorldVelocityTarget(
        frame_id=frame_id,
        velocity_mps=mobility_pb2.Vector3(x=vx, y=vy, z=vz),
    )
    if height_lock_m is not None:
        finite(height_lock_m)
        target.height_lock.height_m = height_lock_m
    message = sunray_pb2.UavDirectControlGoal(
        world_velocity=target,
        yaw=sunray_pb2.YawTarget(mode=sunray_pb2.UAV_YAW_KEEP),
        controller=sunray_pb2.UAV_CONTROLLER_DEFAULT,
        lease_ms=lease_ms,
    )
    validate_uav_direct_control_goal(message)
    return message.SerializeToString()


def direct_body_velocity_payload(
    forward_mps: float,
    left_mps: float,
    *,
    fixed_height_m: float,
    lease_ms: int = 1000,
    yaw_rate: float = 0.0,
) -> bytes:
    finite(forward_mps, left_mps, fixed_height_m, yaw_rate)
    if not 250 <= lease_ms <= 2000:
        raise ValueError("lease_ms must be between 250 and 2000")
    message = sunray_pb2.UavDirectControlGoal(
        body_velocity=sunray_pb2.BodyVelocityTarget(
            body_xy_velocity_mps=mobility_pb2.Vector2(x=forward_mps, y=left_mps),
            fixed_height_m=fixed_height_m,
        ),
        yaw=sunray_pb2.YawTarget(
            mode=sunray_pb2.UAV_YAW_SET_RATE,
            value=yaw_rate,
        ),
        controller=sunray_pb2.UAV_CONTROLLER_DEFAULT,
        lease_ms=lease_ms,
    )
    validate_uav_direct_control_goal(message)
    return message.SerializeToString()


def ugv_move_point_payload(
    x: float,
    y: float,
    *,
    frame_id: str,
    yaw_rad: float = 0.0,
    body: bool = False,
) -> bytes:
    finite(x, y, yaw_rad)
    if not frame_id:
        raise ValueError("frame_id must not be empty")
    message = sunray_pb2.UgvMovePointGoal(
        frame=(sunray_pb2.UGV_MOVE_BODY if body else sunray_pb2.UGV_MOVE_LOCAL),
        point_m=mobility_pb2.Vector3(x=x, y=y, z=0.0),
        yaw_mode=sunray_pb2.UGV_YAW_SET,
        desired_yaw_rad=yaw_rad,
        local_frame_id=frame_id if not body else "",
    )
    validate_ugv_move_point_goal(message)
    return message.SerializeToString()


def ugv_velocity_payload(
    vx: float,
    vy: float,
    *,
    lease_ms: int = 1000,
    frame_id: str = "world",
    body: bool = False,
    yaw_rate_radps: float = 0.0,
) -> bytes:
    finite(vx, vy, yaw_rate_radps)
    if not 250 <= lease_ms <= 2000:
        raise ValueError("lease_ms must be between 250 and 2000")
    if body:
        target = sunray_pb2.UgvBodyVelocityTarget(
            linear_mps=mobility_pb2.Vector2(x=vx, y=vy), yaw_rate_radps=yaw_rate_radps
        )
        message = sunray_pb2.UgvVelocityGoal(body=target, lease_ms=lease_ms)
    else:
        if not frame_id:
            raise ValueError("frame_id must not be empty")
        target = sunray_pb2.UgvLocalVelocityTarget(
            frame_id=frame_id,
            linear_mps=mobility_pb2.Vector2(x=vx, y=vy),
        )
        message = sunray_pb2.UgvVelocityGoal(local=target, lease_ms=lease_ms)
    validate_ugv_velocity_goal(message)
    return message.SerializeToString()


def ugv_hold_payload() -> bytes:
    return sunray_pb2.UgvHoldGoal().SerializeToString()


def planner_cancel_payload() -> bytes:
    return sunray_pb2.PlannerCancelTaskRequest().SerializeToString()


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

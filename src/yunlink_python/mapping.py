"""Livox point-cloud accumulation (sunray mapping.v1) over YunLink RPC."""

from __future__ import annotations

from dataclasses import dataclass

import yunlink
from yunlink.profiles.com.yundrone.sunray.v2 import sunray_pb2

from .actions import ActionResult
from .errors import ActionFailedError
from .profiles import MAPPING_START, MAPPING_STOP, mapping_start_payload, mapping_stop_payload


@dataclass(frozen=True)
class MappingLidarState:
    lidar_name: str
    lidar_topic: str
    imu_topic: str
    lidar_rate_hz: float
    imu_rate_hz: float
    pointcloud_accumulating: bool
    pointcloud_frame_count: int
    lidar_running: bool
    lidar_age_sec: float
    imu_age_sec: float
    lidar_point_num: int
    lidar_actual_count: int


@dataclass(frozen=True)
class MappingState:
    source_stamp_ns: int
    status: str
    error: str
    lidars: tuple[MappingLidarState, ...]


def mapping_state_from_sample(sample) -> MappingState:
    message = sunray_pb2.MappingState()
    message.ParseFromString(sample.data)
    lidars = tuple(
        MappingLidarState(
            lidar_name=item.lidar_name,
            lidar_topic=item.lidar_topic,
            imu_topic=item.imu_topic,
            lidar_rate_hz=item.lidar_rate_hz,
            imu_rate_hz=item.imu_rate_hz,
            pointcloud_accumulating=item.pointcloud_accumulating,
            pointcloud_frame_count=item.pointcloud_frame_count,
            lidar_running=item.lidar_running,
            lidar_age_sec=item.lidar_age_sec,
            imu_age_sec=item.imu_age_sec,
            lidar_point_num=item.lidar_point_num,
            lidar_actual_count=item.lidar_actual_count,
        )
        for item in message.lidars
    )
    return MappingState(
        source_stamp_ns=message.source_stamp_ns,
        status=message.status,
        error=message.error,
        lidars=lidars,
    )


def start_mapping(transport, uid: str, timeout: float) -> ActionResult:
    event = transport.call_rpc(
        uid,
        MAPPING_START,
        mapping_start_payload(),
        authority_scope="com.yundrone.sunray",
        timeout=timeout,
    )
    response = sunray_pb2.MappingStartResponse.FromString(event.payload)
    if not response.success:
        raise ActionFailedError(5, response.message or "mapping start failed")
    return ActionResult(0, yunlink.ActionPhase.SUCCEEDED, 0, response.message)


def stop_mapping(transport, uid: str, timeout: float) -> ActionResult:
    event = transport.call_rpc(
        uid,
        MAPPING_STOP,
        mapping_stop_payload(),
        authority_scope="com.yundrone.sunray",
        timeout=timeout,
    )
    response = sunray_pb2.MappingStopResponse.FromString(event.payload)
    if not response.success:
        raise ActionFailedError(5, response.message or "mapping stop failed")
    return ActionResult(0, yunlink.ActionPhase.SUCCEEDED, 0, response.message)

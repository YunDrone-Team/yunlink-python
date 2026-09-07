from __future__ import annotations

import queue
import threading
import time

import yunlink
from yunlink.core_codec import (
    decode_attachment_request,
    decode_authority_request,
    decode_stream_subscription,
)
from yunlink.profiles.com.yundrone.sunray.v2 import sunray_pb2
from yunlink.profiles.org.yunlink.mobility.v1 import mobility_pb2

from yunlink_python.profiles import MOBILITY, SUNRAY, TELEMETRY


def core_type(name: str) -> yunlink.TypeRef:
    return yunlink.TypeRef("yunlink.core", 2, name)


class FakeBridge:
    def __init__(self) -> None:
        self.runtime = yunlink.Runtime(
            yunlink.RuntimeConfig(
                "bridge.fake",
                0,
                "Fake Bridge",
                profiles=(MOBILITY, TELEMETRY, SUNRAY),
            )
        )
        self.runtime.set_entity_uids(("uav1", "ugv1"))
        self.port = self.runtime.listening_port
        self.action_goals: list[str] = []
        self.attach_requests = 0
        self.reject_actions = False
        self.hold_actions = False
        self._closed = False
        self._thread = threading.Thread(target=self._run, daemon=True)
        self._thread.start()

    def close(self) -> None:
        self._closed = True
        self.runtime.close()
        self._thread.join(timeout=2)

    def disconnect_clients(self) -> None:
        for peer_id in self._peer_ids():
            self.runtime.close_peer(yunlink.Peer(peer_id, "", 0))

    def _peer_ids(self) -> set[str]:
        # Session and envelope events carry the peer IDs used by Runtime.close_peer.
        return set(getattr(self, "_seen_peer_ids", set()))

    def _run(self) -> None:
        self._seen_peer_ids: set[str] = set()
        while not self._closed:
            try:
                event = self.runtime.events.get(timeout=0.1)
            except queue.Empty:
                continue
            if event.peer_id:
                self._seen_peer_ids.add(event.peer_id)
            if event.kind != 1:
                continue
            try:
                self._handle(event)
            except Exception:
                if not self._closed:
                    raise

    def _reply(self, event, family, operation, type_ref, payload=b"", correlation_id=None) -> None:
        self.runtime.publish(
            yunlink.Peer(event.peer_id, "", 0),
            event.session_id,
            family,
            operation,
            yunlink.Target.endpoint(event.source_endpoint_uid),
            type_ref,
            payload,
            correlation_id=event.message_id if correlation_id is None else correlation_id,
            ttl_ms=5000,
        )

    def _handle(self, event) -> None:
        if event.family == yunlink.Family.ENTITY_DIRECTORY and event.operation == 1:
            entity = yunlink.EntityDescriptor(
                "uav1",
                "sunray.uav",
                "Simulation UAV",
                "sim-uav1",
                {"sunray.system_mode": "sim"},
                ("com.yundrone.sunray.uav.flight.v1",),
                yunlink.Availability.ONLINE,
            )
            ugv = yunlink.EntityDescriptor(
                "ugv1", "sunray.ugv", "Simulation UGV", "sim-ugv1",
                {"sunray.system_mode": "sim"},
                ("com.yundrone.sunray.ugv.mobility.v1",), yunlink.Availability.ONLINE,
            )
            directory = yunlink.EntityDirectory("bridge.fake", "r1", (entity, ugv))
            self._reply(event, yunlink.Family.ENTITY_DIRECTORY, 2, core_type("entity_directory"),
                        yunlink.encode_core(directory))
        elif event.family == yunlink.Family.ENTITY_DIRECTORY and event.operation == 4:
            self.attach_requests += 1
            request = decode_attachment_request(event.payload)
            response = yunlink.AttachmentResponse(True, "r1", request.entity_uids, "attached")
            self._reply(event, yunlink.Family.ENTITY_DIRECTORY, 5, core_type("attachment.response"),
                        yunlink.encode_core(response))
        elif event.family == yunlink.Family.AUTHORITY and event.operation == 1:
            request = decode_authority_request(event.payload)
            status = yunlink.AuthorityStatus(request.authority_scope, "controller", 300000, 0)
            self._reply(event, yunlink.Family.AUTHORITY, 4, core_type("authority.status"),
                        yunlink.encode_core(status))
        elif event.family == yunlink.Family.STREAM and event.operation == 1:
            catalog = yunlink.StreamCatalog("s1", tuple(self._stream_descriptors()))
            self._reply(event, yunlink.Family.STREAM, 2, core_type("stream.catalog"),
                        yunlink.encode_core(catalog))
        elif event.family == yunlink.Family.STREAM and event.operation == 3:
            request = decode_stream_subscription(event.payload)
            status = yunlink.StreamSubscriptionStatus(
                True, True, request.stream_uid, request.max_rate_hz, request.max_payload_bytes
            )
            self._reply(event, yunlink.Family.STREAM, 6, core_type("stream.subscription.status"),
                        yunlink.encode_core(status))
            self._publish_initial_sample(event, request.stream_uid)
        elif event.family == yunlink.Family.ACTION and event.operation == 1:
            self.action_goals.append(event.type_ref.type_name)
            self._action_update(event, yunlink.ActionPhase.RECEIVED, "received")
            if self.hold_actions:
                return
            if self.reject_actions:
                self._action_update(event, yunlink.ActionPhase.FAILED, "rejected", result_code=5)
                return
            self._action_update(event, yunlink.ActionPhase.RUNNING, "running")
            if event.type_ref.type_name == "UavNavGoal":
                goal = sunray_pb2.UavNavGoal.FromString(event.payload)
                self._publish_odometry(event, goal.position_m.x, goal.position_m.y, goal.position_m.z)
            elif event.type_ref.type_name == "UavWaypointMissionGoal":
                goal = sunray_pb2.UavWaypointMissionGoal.FromString(event.payload)
                waypoint = goal.waypoints[0]
                self._publish_odometry(
                    event,
                    waypoint.position_m.x,
                    waypoint.position_m.y,
                    waypoint.position_m.z,
                )
            elif event.type_ref.type_name == "UgvMovePointGoal":
                goal = sunray_pb2.UgvMovePointGoal.FromString(event.payload)
                self._publish_ugv_odometry(event, goal.point_m.x, goal.point_m.y)
            self._action_update(event, yunlink.ActionPhase.SUCCEEDED, "completed")
        elif event.family == yunlink.Family.ACTION and event.operation == 3:
            self._action_update(
                event, yunlink.ActionPhase.CANCELLED, "cancelled", correlation_id=event.correlation_id
            )
        elif event.family == yunlink.Family.RPC and event.operation == 1:
            if event.type_ref.type_name == "PlannerCancelTaskRequest":
                response = sunray_pb2.PlannerCancelTaskResponse(
                    accepted=True, message="cancelled"
                )
                self._reply(
                    event,
                    yunlink.Family.RPC,
                    2,
                    yunlink.TypeRef("com.yundrone.sunray", 2, "PlannerCancelTaskResponse", 1),
                    response.SerializeToString(),
                )

    def _action_update(self, event, phase, detail, result_code=0, correlation_id=None) -> None:
        update = yunlink.ActionUpdate(phase, result_code, 100 if phase.terminal else 20, detail)
        self._reply(
            event,
            yunlink.Family.ACTION,
            2,
            event.type_ref,
            yunlink.encode_core(update),
            correlation_id,
        )

    def _stream_descriptors(self):
        yield yunlink.StreamDescriptor(
            "uav1.odometry", yunlink.TypeRef("org.yunlink.mobility", 1, "Odometry"), "protobuf"
        )
        yield yunlink.StreamDescriptor(
            "uav1.flight_control_state",
            yunlink.TypeRef("com.yundrone.sunray", 2, "FlightControlState"),
            "protobuf",
        )
        yield yunlink.StreamDescriptor(
            "uav1.uav_planning_state",
            yunlink.TypeRef("com.yundrone.sunray", 2, "UavPlanningState", 2),
            "protobuf",
        )
        yield yunlink.StreamDescriptor(
            "ugv1.odometry", yunlink.TypeRef("org.yunlink.mobility", 1, "Odometry"), "protobuf"
        )
        yield yunlink.StreamDescriptor(
            "ugv1.ugv_control_state",
            yunlink.TypeRef("com.yundrone.sunray", 2, "UgvControlState", 5), "protobuf"
        )
        yield yunlink.StreamDescriptor(
            "ugv1.ugv_planning_state",
            yunlink.TypeRef("com.yundrone.sunray", 2, "UgvPlanningState", 6), "protobuf"
        )

    def _publish_initial_sample(self, event, stream_uid: str) -> None:
        if stream_uid.endswith(".odometry"):
            if stream_uid.startswith("ugv1."):
                self._publish_ugv_odometry(event, 0.0, 0.0)
            else:
                self._publish_odometry(event, 0.0, 0.0, 0.0)
        elif stream_uid.endswith(".flight_control_state"):
            message = sunray_pb2.FlightControlState(
                armed=False, landed=True, battery_voltage_v=16.2, battery_percent=90
            )
            self._publish_sample(event, stream_uid, message.SerializeToString())
        elif stream_uid.endswith(".uav_planning_state"):
            message = sunray_pb2.UavPlanningState(
                main_state=sunray_pb2.UAV_PLANNING_MAIN_WAIT_MISSION,
                task_state=sunray_pb2.UAV_PLANNING_TASK_IDLE,
                planner_frame_id="world",
            )
            self._publish_sample(event, stream_uid, message.SerializeToString())
        elif stream_uid.endswith(".ugv_control_state"):
            self._publish_sample(event, stream_uid, sunray_pb2.UgvControlState(odom_ready=True).SerializeToString())
        elif stream_uid.endswith(".ugv_planning_state"):
            self._publish_sample(event, stream_uid, sunray_pb2.UgvPlanningState(
                main_state=1, task_state=0, planner_frame_id="world"
            ).SerializeToString())

    def _publish_odometry(self, event, x: float, y: float, z: float) -> None:
        message = mobility_pb2.Odometry(
            frame_id="world",
            child_frame_id="base_link",
            pose=mobility_pb2.Pose(position=mobility_pb2.Vector3(x=x, y=y, z=z)),
        )
        self._publish_sample(event, "uav1.odometry", message.SerializeToString())

    def _publish_ugv_odometry(self, event, x: float, y: float) -> None:
        message = mobility_pb2.Odometry(
            frame_id="world", child_frame_id="base_link",
            pose=mobility_pb2.Pose(position=mobility_pb2.Vector3(x=x, y=y, z=0.0)),
        )
        self._publish_sample(event, "ugv1.odometry", message.SerializeToString())

    def _publish_sample(self, event, stream_uid: str, data: bytes) -> None:
        sample = yunlink.StreamSample(stream_uid, "protobuf", {}, time.time_ns(), 1, data)
        self.runtime.publish(
            yunlink.Peer(event.peer_id, "", 0),
            event.session_id,
            yunlink.Family.STREAM,
            4,
            yunlink.Target.endpoint(event.source_endpoint_uid),
            core_type("stream.sample"),
            yunlink.encode_core(sample),
            ttl_ms=5000,
            source_entity_uid="uav1",
        )

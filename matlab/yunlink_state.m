function state = yunlink_state(vehicle)
%YUNLINK_STATE Return a MATLAB struct with the latest UAV state.
raw = yunlink_state_raw(vehicle);

state = struct();
state.uavId = char(string(vehicle.uid));
state.frameId = char(string(raw.frame_id));
state.connected = logical(raw.connected);
state.fresh = logical(raw.fresh);
state.position = vector3_struct(raw.position);
state.velocity = vector3_struct(raw.velocity);
state.attitude = quaternion_struct(raw.attitude);
state.angularVelocity = vector3_struct(raw.angular_velocity);
state.armed = logical(raw.armed);
state.disarmed = logical(raw.disarmed);
state.landed = logical(raw.landed);
state.landing = logical(raw.landing);
state.batteryVoltageV = double(raw.battery_voltage_v);
state.batteryPercent = double(raw.battery_percent);
state.px4Mode = char(string(raw.px4_mode));
state.controlMode = double(raw.control_mode);
state.controlModeName = char(string(raw.control_mode_name));
state.controlState = double(raw.control_state);
state.movementMode = char(string(raw.movement_mode));
state.manualOverride = logical(raw.manual_override);
state.controllerType = double(raw.controller_type);
state.localization = struct( ...
    'valid', logical(raw.localization.valid), ...
    'source', double(raw.localization.source), ...
    'updateHz', double(raw.localization.update_hz), ...
    'message', char(string(raw.localization.message)));
state.planner = planner_struct(raw.planner);
state.receivedAt = double(raw.received_at);
end

function value = vector3_struct(vector)
value = struct('x', double(vector.x), 'y', double(vector.y), 'z', double(vector.z));
end

function value = quaternion_struct(quaternion)
value = struct( ...
    'x', double(quaternion.x), ...
    'y', double(quaternion.y), ...
    'z', double(quaternion.z), ...
    'w', double(quaternion.w));

% Derived Euler angles are display conveniences; the quaternion remains canonical.
sinr = 2 * (value.w * value.x + value.y * value.z);
cosr = 1 - 2 * (value.x^2 + value.y^2);
value.rollRad = atan2(sinr, cosr);
sinp = 2 * (value.w * value.y - value.z * value.x);
value.pitchRad = asin(max(-1, min(1, sinp)));
siny = 2 * (value.w * value.z + value.x * value.y);
cosy = 1 - 2 * (value.y^2 + value.z^2);
value.yawRad = atan2(siny, cosy);
end

function value = planner_struct(planner)
value = struct( ...
    'mainState', double(planner.main_state), ...
    'taskState', double(planner.task_state), ...
    'taskName', char(string(planner.task_name)), ...
    'currentWaypointIndex', double(planner.current_waypoint_index), ...
    'totalWaypoints', double(planner.total_waypoints), ...
    'distanceToGoalM', double(planner.distance_to_goal_m), ...
    'holdRemainingS', double(planner.hold_remaining_s), ...
    'failureReason', char(string(planner.failure_reason)));
end

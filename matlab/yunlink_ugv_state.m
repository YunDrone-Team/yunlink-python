function state = yunlink_ugv_state(ugv)
%YUNLINK_UGV_STATE 最新无人车状态。不发送运动指令。
raw = ugv.state;
state = struct();
state.ugvId = char(string(ugv.uid));
state.frameId = char(string(raw.frame_id));
state.connected = logical(raw.connected);
state.fresh = logical(raw.is_fresh());
state.position = struct('x', double(raw.position.x), 'y', double(raw.position.y), 'z', double(raw.position.z));
state.velocity = struct('x', double(raw.velocity.x), 'y', double(raw.velocity.y), 'z', double(raw.velocity.z));
state.controlState = double(raw.control_state);
state.plannerState = double(raw.planner_state);
state.receivedAt = double(raw.received_at);
end

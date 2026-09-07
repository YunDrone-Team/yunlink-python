%HOME_CONNECTIVITY Exercise the non-Planner MATLAB/YunLink path.
% Run only when the selected Bridge endpoint is a controlled test system.
% This script deliberately skips waypoint/planner actions and emergency lock.

if ~exist('YUNLINK_ADDRESS', 'var')
    address = getenv('YUNLINK_ADDRESS');
    if isempty(address)
        address = '192.168.31.236:9696';
    end
else
    address = YUNLINK_ADDRESS;
end

if ~exist('YUNLINK_ENTITY', 'var')
    entity = getenv('YUNLINK_ENTITY');
    if isempty(entity)
        entity = 'uav1';
    end
else
    entity = YUNLINK_ENTITY;
end

client = yunlink_connect(address);
cleanup = onCleanup(@() yunlink_close(client)); %#ok<NASGU>
uav = yunlink_vehicle(client, entity);

initial = yunlink_state(uav);
assert(initial.connected && initial.fresh, 'UAV state is not fresh after attach.');
fprintf('Connected to %s (%s), frame=%s, landed=%d, armed=%d\n', ...
    initial.uavId, address, initial.frameId, initial.landed, initial.armed);

% The non-Planner path is intentionally short and bounded.
yunlink_takeoff(uav, 1.0, 30);
afterTakeoff = yunlink_state(uav);
assert(afterTakeoff.connected && ~afterTakeoff.landed, ...
    'UAV did not report airborne state after takeoff.');

yunlink_position_control(uav, afterTakeoff.position.x + 0.2, ...
    afterTakeoff.position.y, 1.0, 0.0, 30);
afterPosition = yunlink_state(uav);
fprintf('Position=(%.3f, %.3f, %.3f), mode=%s, movement=%s\n', ...
    afterPosition.position.x, afterPosition.position.y, afterPosition.position.z, ...
    afterPosition.px4Mode, afterPosition.movementMode);

yunlink_hover(uav, 15);
yunlink_land(uav, 30);
% Action completion and telemetry publication are asynchronous; allow a
% bounded settling window before asserting the controller state.
settled = tic;
final = yunlink_state(uav);
while ~final.landed && toc(settled) < 10
    pause(0.2);
    final = yunlink_state(uav);
end
assert(final.connected && final.landed, 'UAV did not report landed state.');
fprintf('Completed non-Planner MATLAB connectivity test; landed=%d, armed=%d\n', ...
    final.landed, final.armed);

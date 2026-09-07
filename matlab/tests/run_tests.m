%RUN_TESTS Run MATLAB-side smoke checks without connecting to a vehicle.
root = fileparts(fileparts(mfilename('fullpath')));
required = {
    'yunlink_connect.m', 'yunlink_vehicle.m', 'yunlink_state.m', ...
    'yunlink_state_raw.m', 'yunlink_takeoff.m', 'yunlink_move_to.m', ...
    'yunlink_position_control.m', 'yunlink_velocity_control.m', ...
    'yunlink_waypoint.m', 'yunlink_hover.m', 'yunlink_return_home.m', ...
    'yunlink_cancel.m', 'yunlink_land.m', 'yunlink_emergency_lock.m', ...
    'yunlink_command.m', 'yunlink_monitor.m', 'yunlink_setup.m', ...
    'yunlink_update.m'};
manifests = {'build_toolbox.m', 'yunlink_sunray.prj'};
for index = 1:numel(required)
    assert(isfile(fullfile(root, required{index})), ...
        'Missing MATLAB wrapper: %s', required{index});
end
for index = 1:numel(manifests)
    assert(isfile(fullfile(root, manifests{index})), ...
        'Missing MATLAB packaging file: %s', manifests{index});
end

% These controls are intentionally absent: arm/disarm are read-only state.
assert(~isfile(fullfile(root, 'yunlink_arm.m')));
assert(~isfile(fullfile(root, 'yunlink_disarm.m')));

% Parse every wrapper so syntax errors are caught even in a no-device run.
addpath(root);
for index = 1:numel(required)
    [folder, name] = fileparts(required{index}); %#ok<ASGLU>
    assert(exist(name, 'file') == 2, 'MATLAB cannot resolve %s', name);
end
fprintf('YunLink MATLAB smoke checks passed (%d wrappers).\n', numel(required));

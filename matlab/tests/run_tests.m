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
docs = {'README.md', 'getting_started.html', 'getting_started.m'};
examples = {'examples/read_state_demo.m', 'examples/basic_flight_demo.m'};
developer = {'developer/README.md', 'developer/build_release_bundle.m', ...
    'build_toolbox.m', 'yunlink_sunray.prj', 'tests/home_connectivity.m'};
for index = 1:numel(required)
    assert(isfile(fullfile(root, required{index})), ...
        'Missing MATLAB wrapper: %s', required{index});
end
for index = 1:numel(docs)
    assert(isfile(fullfile(root, docs{index})), ...
        'Missing user documentation: %s', docs{index});
end
for index = 1:numel(examples)
    assert(isfile(fullfile(root, examples{index})), ...
        'Missing MATLAB example: %s', examples{index});
end
for index = 1:numel(developer)
    assert(isfile(fullfile(root, developer{index})), ...
        'Missing MATLAB packaging file: %s', developer{index});
end

% These controls are intentionally absent: arm/disarm are read-only state.
assert(~isfile(fullfile(root, 'yunlink_arm.m')));
assert(~isfile(fullfile(root, 'yunlink_disarm.m')));

setupSource = fileread(fullfile(root, 'yunlink_setup.m'));
assert(contains(setupSource, 'nargin == 0'), ...
    'yunlink_setup must support the no-argument wizard.');
assert(contains(setupSource, 'uigetfile'), ...
    'yunlink_setup wizard must use MATLAB file selection.');
assert(~contains(setupSource, 'yunlink_connect('), ...
    'yunlink_setup must not connect to a vehicle.');

packSource = fileread(fullfile(root, 'build_toolbox.m'));
assert(contains(packSource, 'getting_started.html'));
assert(contains(packSource, 'getting_started.m'));
assert(contains(packSource, 'ToolboxFiles'));
assert(contains(packSource, 'vendor'));

demoSource = fileread(fullfile(root, 'examples', 'basic_flight_demo.m'));
assert(contains(demoSource, 'sends flight commands') || contains(demoSource, 'flight commands'));
readSource = fileread(fullfile(root, 'examples', 'read_state_demo.m'));
assert(contains(readSource, 'does not send flight commands'));

% Parse every wrapper so syntax errors are caught even in a no-device run.
addpath(root);
for index = 1:numel(required)
    [folder, name] = fileparts(required{index}); %#ok<ASGLU>
    assert(exist(name, 'file') == 2, 'MATLAB cannot resolve %s', name);
end
assert(exist('build_toolbox', 'file') == 2, 'MATLAB cannot resolve build_toolbox');
fprintf('YunLink MATLAB smoke checks passed (%d wrappers).\n', numel(required));

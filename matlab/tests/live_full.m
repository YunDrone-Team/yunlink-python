%LIVE_FULL Run MATLAB wrappers against a live Bridge. No GUI.
address = getenv('YUNLINK_ADDRESS');
if isempty(address)
    address = '192.168.31.236:9696';
end
uavUid = getenv('YUNLINK_UAV');
if isempty(uavUid)
    uavUid = 'e-f97f96-2-1';
end
ugvUid = getenv('YUNLINK_UGV');
if isempty(ugvUid)
    ugvUid = 'e-f97f96-3-1';
end
doFlight = strcmp(getenv('YUNLINK_LIVE_FLIGHT'), '1');

root = fileparts(fileparts(mfilename('fullpath')));
addpath(root);
run(fullfile(root, 'tests', 'run_tests.m'));

fprintf('\n== discover ==\n');
bridges = yunlink_discover(5);
assert(~isempty(bridges), 'discover returned no Bridge');
fprintf('found %d: %s\n', numel(bridges), bridges(1).discoveryId);

fprintf('\n== connect / directory ==\n');
client = yunlink_connect(address);
cleanup = onCleanup(@() yunlink_close(client));
infos = yunlink_entities(client);
assert(~isempty(infos), 'directory is empty');
for index = 1:numel(infos)
    fprintf('  %s  %s  %s\n', infos(index).uid, infos(index).name, infos(index).kind);
end

fprintf('\n== UAV state ==\n');
uav = yunlink_vehicle(client, uavUid);
pause(0.8);
state = yunlink_state(uav);
assert(state.connected, 'UAV not connected');
fprintf('uav=%s fresh=%d landed=%d pos=[%.3f %.3f %.3f]\n', ...
    state.uavId, state.fresh, state.landed, state.position.x, state.position.y, state.position.z);

fprintf('\n== UGV state ==\n');
ugv = yunlink_ugv(client, ugvUid);
pause(0.8);
ugvState = yunlink_ugv_state(ugv);
assert(ugvState.connected, 'UGV not connected');
fprintf('ugv=%s fresh=%d pos=[%.3f %.3f %.3f]\n', ...
    ugvState.ugvId, ugvState.fresh, ugvState.position.x, ugvState.position.y, ugvState.position.z);

if doFlight
    fprintf('\n== UAV takeoff / hover / land ==\n');
    if ~yunlink_state(uav).landed
        fprintf('already airborne, landing first\n');
        yunlink_land(uav, 30);
        pause(2);
    end
    yunlink_takeoff(uav, 1.0, 30);
    airborne = yunlink_state(uav);
    assert(~airborne.landed, 'UAV still landed after takeoff');
    yunlink_hover(uav, 10);
    yunlink_land(uav, 30);
    settled = tic;
    final = yunlink_state(uav);
    while ~final.landed && toc(settled) < 12
        pause(0.3);
        final = yunlink_state(uav);
    end
    assert(final.landed, 'UAV did not land');

    fprintf('\n== UGV move / hold ==\n');
    start = yunlink_ugv_state(ugv).position;
    yunlink_ugv_move_to(ugv, start.x + 0.2, start.y, 30);
    yunlink_ugv_hold(ugv, 10);
end

fprintf('\nMATLAB live_full passed (flight=%d).\n', doFlight);

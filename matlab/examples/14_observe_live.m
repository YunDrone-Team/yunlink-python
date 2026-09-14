% 14_OBSERVE_LIVE  Refresh UAV/UGV state in the command window.
% This example does not send flight commands. Ctrl-C to stop.

address = "192.168.31.236:9696";
uavUid = "";
seconds = 0;
hz = 2;

client = yunlink_connect(address);
cleanup = onCleanup(@() yunlink_close(client));
infos = yunlink_entities(client);
if strlength(uavUid) > 0
    infos = infos(strcmp({infos.uid}, char(uavUid)) | strcmp({infos.name}, char(uavUid)));
end
infos = infos(ismember({infos.kind}, {'sunray.uav', 'sunray.ugv'}));
if isempty(infos)
    error('yunlink:NoDevice', 'No matching UAV/UGV was listed.');
end

devices = cell(1, numel(infos));
for index = 1:numel(infos)
    if strcmp(infos(index).kind, 'sunray.uav')
        devices{index} = yunlink_vehicle(client, infos(index).uid);
    else
        devices{index} = yunlink_ugv(client, infos(index).uid);
    end
end

started = tic;
frames = 0;
while seconds <= 0 || toc(started) < seconds
    frames = frames + 1;
    clc
    fprintf('YunLink live observe  frames=%d  elapsed=%.1fs  Ctrl-C to stop\n', frames, toc(started));
    fprintf('Bridge %s  %s\n\n', string(client.bridge_uid), string(client.bridge_address));
    for index = 1:numel(infos)
        if strcmp(infos(index).kind, 'sunray.uav')
            state = yunlink_state(devices{index});
            fprintf('无人机  %s  %s\n', infos(index).name, infos(index).uid);
            fprintf('  位置     x=%.3f  y=%.3f  z=%.3f\n', state.position.x, state.position.y, state.position.z);
            fprintf('  速度     x=%.3f  y=%.3f  z=%.3f\n', state.velocity.x, state.velocity.y, state.velocity.z);
            fprintf('  解锁     %d   落地 %d   新鲜 %d   电量 %g%%\n', ...
                state.armed, state.landed, state.fresh, state.batteryPercent);
            fprintf('  模式     %s  %s\n\n', state.px4Mode, state.movementMode);
        else
            state = yunlink_ugv_state(devices{index});
            fprintf('无人车  %s  %s\n', infos(index).name, infos(index).uid);
            fprintf('  位置     x=%.3f  y=%.3f  z=%.3f\n', state.position.x, state.position.y, state.position.z);
            fprintf('  速度     x=%.3f  y=%.3f  z=%.3f\n', state.velocity.x, state.velocity.y, state.velocity.z);
            fprintf('  新鲜     %d   控制 %g   规划 %g\n\n', state.fresh, state.controlState, state.plannerState);
        end
    end
    pause(1 / hz);
end

% 14_OBSERVE_LIVE  在命令窗口刷新 UAV/UGV 状态。
% 本示例不发送飞行指令。Ctrl-C 结束。

address = string(getenv('YUNLINK_ADDRESS'));
if strlength(address) == 0
    address = "192.168.10.10:9696";
end
uavUid = "";
seconds = 0;
hz = 2;
if seconds <= 0 && ~usejava('desktop')
    seconds = 2;
end

client = yunlink_connect(address);
cleanup = onCleanup(@() yunlink_close(client));
infos = yunlink_entities(client);
if strlength(uavUid) > 0
    infos = infos(strcmp({infos.uid}, char(uavUid)) | strcmp({infos.name}, char(uavUid)));
end
infos = infos(ismember({infos.kind}, {'sunray.uav', 'sunray.ugv'}));
if isempty(infos)
    error('yunlink:NoDevice', '目录中没有匹配的 UAV/UGV。');
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
    fprintf('YunLink 实时观测  帧=%d  已运行=%.1fs  Ctrl-C 结束\n', frames, toc(started));
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

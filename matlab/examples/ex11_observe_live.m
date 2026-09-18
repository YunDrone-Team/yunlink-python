% 11_OBSERVE_LIVE  命令窗口刷新遥测。
%
% 做什么：只读。不飞。桌面下 Ctrl-C 结束。
% 会不会飞：不会。
% 本步要读：yunlink.env 的 YUNLINK_ADDRESS。可把 YUNLINK_UAV 填成只看一架。
% 上一步：ex10。下一步：ex12 全量检查。

[address, uavUid] = yunlink_example_target();
% 0 表示一直刷到 Ctrl-C。无桌面（-batch）时下面会改成 2 秒，避免挂死。
seconds = 0;
% 刷新频率，单位 Hz。2 表示大约每 0.5 秒清屏打一次。
hz = 2;
if seconds <= 0 && ~usejava('desktop')
    seconds = 2;
end

client = yunlink_connect(address);
cleanup = onCleanup(@() yunlink_close(client));
infos = yunlink_entities(client);
if strlength(uavUid) > 0
    % 填了 YUNLINK_UAV 就只看这一台。
    infos = infos(strcmp({infos.uid}, char(uavUid)) | strcmp({infos.name}, char(uavUid)));
end
infos = infos(ismember({infos.kind}, {'sunray.uav', 'sunray.ugv'}));
if isempty(infos)
    error('yunlink:NoDevice', '目录中没有匹配的 UAV/UGV。把 entity_uid 写入 YUNLINK_UAV=。');
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
    fprintf('只读观测  帧=%d  已运行=%.1fs  Ctrl-C 结束\n', frames, toc(started));
    fprintf('Bridge %s  %s\n\n', string(client.bridge_uid), string(client.bridge_address));
    for index = 1:numel(infos)
        if strcmp(infos(index).kind, 'sunray.uav')
            state = yunlink_state(devices{index});
            fprintf('无人机  名称=%s  entity_uid=%s\n', infos(index).name, infos(index).uid);
            fprintf('  位置     x=%.3f  y=%.3f  z=%.3f\n', state.position.x, state.position.y, state.position.z);
            fprintf('  速度     x=%.3f  y=%.3f  z=%.3f\n', state.velocity.x, state.velocity.y, state.velocity.z);
            fprintf('  解锁     %d   落地 %d   新鲜 %d   电量 %g%%\n', ...
                state.armed, state.landed, state.fresh, state.batteryPercent);
            fprintf('  模式     %s  %s\n\n', state.px4Mode, state.movementMode);
        else
            state = yunlink_ugv_state(devices{index});
            fprintf('无人车  名称=%s  entity_uid=%s\n', infos(index).name, infos(index).uid);
            fprintf('  位置     x=%.3f  y=%.3f  z=%.3f\n', state.position.x, state.position.y, state.position.z);
            fprintf('  速度     x=%.3f  y=%.3f  z=%.3f\n', state.velocity.x, state.velocity.y, state.velocity.z);
            fprintf('  新鲜     %d   控制 %g   规划 %g\n\n', state.fresh, state.controlState, state.plannerState);
        end
    end
    % 1/hz 秒睡一次，例如 hz=2 就是 0.5 秒。
    pause(1 / hz);
end

% 13_MULTI_DEVICE_STATE  连续打印全部 UAV/UGV 状态。
%
% 做什么：只读，不飞。
% 本步要读：yunlink.env 的 YUNLINK_ADDRESS。

[address, ~, ~] = yunlink_example_target();
seconds = 8;

client = yunlink_connect(address);
cleanup = onCleanup(@() yunlink_close(client));
infos = yunlink_entities(client);
devices = {};
labels = {};
for index = 1:numel(infos)
    item = infos(index);
    if strcmp(item.kind, 'sunray.uav')
        devices{end + 1} = yunlink_vehicle(client, item.uid); %#ok<AGROW>
        labels{end + 1} = "UAV " + string(item.uid); %#ok<AGROW>
    elseif strcmp(item.kind, 'sunray.ugv')
        devices{end + 1} = yunlink_ugv(client, item.uid); %#ok<AGROW>
        labels{end + 1} = "UGV " + string(item.uid); %#ok<AGROW>
    end
end
if isempty(devices)
    error('yunlink:NoDevice', 'Bridge 目录中没有 UAV 或 UGV。');
end

deadline = posixtime(datetime('now')) + seconds;
while posixtime(datetime('now')) < deadline
    clc
    fprintf('只读刷新，不会飞。t+%.1fs\n', seconds - (deadline - posixtime(datetime('now'))));
    for index = 1:numel(devices)
        if startsWith(labels{index}, "UAV")
            state = yunlink_state(devices{index});
            fprintf('%s fresh=%d xyz=[%.2f %.2f %.2f] batt=%g\n', ...
                labels{index}, state.fresh, state.position.x, state.position.y, state.position.z, state.batteryPercent);
        else
            state = yunlink_ugv_state(devices{index});
            fprintf('%s fresh=%d xyz=[%.2f %.2f %.2f]\n', ...
                labels{index}, state.fresh, state.position.x, state.position.y, state.position.z);
        end
    end
    pause(0.5);
end

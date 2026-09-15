% 11_MULTI_DEVICE_CONTROL  attach 目录中全部 UAV/UGV 并打印状态。
% 本示例不发送运动指令。

address = string(getenv('YUNLINK_ADDRESS'));
if strlength(address) == 0
    address = "192.168.10.10:9696";
end

client = yunlink_connect(address);
cleanup = onCleanup(@() yunlink_close(client));
infos = yunlink_entities(client);
count = 0;
for index = 1:numel(infos)
    item = infos(index);
    if strcmp(item.kind, 'sunray.uav')
        device = yunlink_vehicle(client, item.uid);
        state = yunlink_state(device);
        fprintf('UAV %s fresh=%d pos=[%.2f %.2f %.2f]\n', ...
            item.uid, state.fresh, state.position.x, state.position.y, state.position.z);
        count = count + 1;
    elseif strcmp(item.kind, 'sunray.ugv')
        device = yunlink_ugv(client, item.uid);
        state = yunlink_ugv_state(device);
        fprintf('UGV %s fresh=%d pos=[%.2f %.2f %.2f]\n', ...
            item.uid, state.fresh, state.position.x, state.position.y, state.position.z);
        count = count + 1;
    end
end
if count == 0
    error('yunlink:NoDevice', 'Bridge 目录中没有 UAV 或 UGV。');
end

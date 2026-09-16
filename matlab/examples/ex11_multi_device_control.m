% 11_MULTI_DEVICE_CONTROL  attach 目录里全部 UAV/UGV，只打印状态。
%
% 做什么：不飞、不走。看多机目录。
% 本步要读：yunlink.env 的 YUNLINK_ADDRESS。

[address, ~, ~] = yunlink_example_target();

client = yunlink_connect(address);
cleanup = onCleanup(@() yunlink_close(client));
infos = yunlink_entities(client);
fprintf('目录（第一列 entity_uid）：\n');
yunlink_print_catalog(infos);

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

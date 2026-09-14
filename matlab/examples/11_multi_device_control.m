% 11_MULTI_DEVICE_CONTROL  Attach every UAV/UGV in the directory and print state.
% This example does not send motion commands.

address = "192.168.31.236:9696";

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
    error('yunlink:NoDevice', 'No UAV or UGV was listed in the Bridge directory.');
end

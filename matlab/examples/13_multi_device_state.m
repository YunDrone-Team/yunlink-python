% 13_MULTI_DEVICE_STATE  Print UAV/UGV state for several seconds.
% This example does not send flight commands.

address = "192.168.31.236:9696";
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
    error('yunlink:NoDevice', 'No UAV or UGV was listed in the Bridge directory.');
end

deadline = posixtime(datetime('now')) + seconds;
while posixtime(datetime('now')) < deadline
    clc
    fprintf('t+%.1fs\n', seconds - (deadline - posixtime(datetime('now'))));
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

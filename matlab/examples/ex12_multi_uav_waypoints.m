% 12_MULTI_UAV_WAYPOINTS  给每架 UAV 一条两点短航线。
%
% 做什么：会飞。目录里所有 UAV 都会动。
% 本步要读：yunlink.env 的 YUNLINK_ADDRESS。确认现场允许多机起飞。

[address, ~, ~] = yunlink_example_target();
height = 1.0;

fprintf('本脚本会让目录中每一架 UAV 起飞。\n');
client = yunlink_connect(address);
cleanup = onCleanup(@() yunlink_close(client));
infos = yunlink_entities(client);
uavs = infos(strcmp({infos.kind}, 'sunray.uav'));
if isempty(uavs)
    error('yunlink:NoDevice', 'Bridge 目录中没有 UAV。');
end
fprintf('将控制 %d 架 UAV。entity_uid：\n', numel(uavs));
yunlink_print_catalog(uavs);

vehicles = cell(1, numel(uavs));
try
    for index = 1:numel(uavs)
        vehicles{index} = yunlink_vehicle(client, uavs(index).uid);
        if yunlink_state(vehicles{index}).landed
            yunlink_takeoff(vehicles{index}, height, 30);
        end
    end
    for index = 1:numel(uavs)
        pos = yunlink_state(vehicles{index}).position;
        offset = 0.2 * index;
        points = [
            pos.x + offset, pos.y, height
            pos.x + offset, pos.y + 0.2, height
            ];
        yunlink_waypoints(vehicles{index}, points, 120);
    end
finally
    for index = 1:numel(vehicles)
        if ~isempty(vehicles{index}) && ~yunlink_state(vehicles{index}).landed
            yunlink_land(vehicles{index}, 30);
        end
    end
end
fprintf('完成。\n');

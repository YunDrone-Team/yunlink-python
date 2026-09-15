% 12_MULTI_UAV_WAYPOINTS  给每架 UAV 一条两点短航线。
% 本示例会发送飞行指令。

address = "192.168.31.236:9696";
height = 1.0;

client = yunlink_connect(address);
cleanup = onCleanup(@() yunlink_close(client));
infos = yunlink_entities(client);
uavs = infos(strcmp({infos.kind}, 'sunray.uav'));
if isempty(uavs)
    error('yunlink:NoDevice', 'Bridge 目录中没有 UAV。');
end

vehicles = cell(1, numel(uavs));
try
    for index = 1:numel(uavs)
        vehicles{index} = yunlink_vehicle(client, uavs(index).uid);
        disp(yunlink_takeoff(vehicles{index}, height, 30));
    end
    for index = 1:numel(uavs)
        pos = yunlink_state(vehicles{index}).position;
        offset = 0.2 * index;
        points = [
            pos.x + offset, pos.y, height
            pos.x + offset, pos.y + 0.2, height
            ];
        disp(yunlink_waypoints(vehicles{index}, points, 120));
    end
finally
    for index = 1:numel(vehicles)
        if ~isempty(vehicles{index}) && ~yunlink_state(vehicles{index}).landed
            disp(yunlink_land(vehicles{index}, 30));
        end
    end
end

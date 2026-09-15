% 05_WAYPOINTS  起飞、执行两点航线，然后降落。
% 本示例会发送飞行指令。

address = string(getenv('YUNLINK_ADDRESS'));
if strlength(address) == 0
    address = "192.168.10.10:9696";
end
uavUid = string(getenv('YUNLINK_UAV'));
if strlength(uavUid) == 0
    uavUid = "e-89c423-2-1";
end
height = 1.0;

client = yunlink_connect(address);
cleanup = onCleanup(@() yunlink_close(client));
uav = yunlink_vehicle(client, uavUid);

try
    if yunlink_state(uav).landed
        fprintf('起飞\n');
        yunlink_takeoff(uav, height, 30);
    end
    pos = yunlink_state(uav).position;
    points = [
        pos.x + 0.25, pos.y, height
        pos.x + 0.25, pos.y + 0.25, height
        ];
    fprintf('航点任务\n');
    yunlink_waypoints(uav, points, 120);
    disp(yunlink_state(uav).planner);
finally
    if ~yunlink_state(uav).landed
        fprintf('降落\n');
        yunlink_land(uav, 30);
    end
end
fprintf('完成。\n');

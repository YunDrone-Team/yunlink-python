% 05_WAYPOINTS  起飞、执行两点航线，然后降落。
% 本示例会发送飞行指令。

address = "192.168.31.236:9696";
uavUid = "e-f97f96-2-1";
height = 1.0;

client = yunlink_connect(address);
cleanup = onCleanup(@() yunlink_close(client));
uav = yunlink_vehicle(client, uavUid);

try
    disp(yunlink_takeoff(uav, height, 30));
    pos = yunlink_state(uav).position;
    points = [
        pos.x + 0.25, pos.y, height
        pos.x + 0.25, pos.y + 0.25, height
        ];
    disp(yunlink_waypoints(uav, points, 120));
    disp(yunlink_state(uav).planner);
finally
    if ~yunlink_state(uav).landed
        disp(yunlink_land(uav, 30));
    end
end

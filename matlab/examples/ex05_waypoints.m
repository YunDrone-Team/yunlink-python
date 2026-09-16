% 05_WAYPOINTS  起飞后走两点航线，再降落。
%
% 做什么：Planner 多航点。会飞。
% 本步要读：yunlink.env 的 YUNLINK_ADDRESS、YUNLINK_UAV。
% 上一步：ex04。不要改本文件中间的变量。

[address, uavUid] = yunlink_example_target();
height = 1.0;

fprintf('本脚本会起飞并提交航线。\n');
client = yunlink_connect(address);
cleanup = onCleanup(@() yunlink_close(client));
uavUid = yunlink_example_pick(client, "sunray.uav", uavUid);
uav = yunlink_vehicle(client, uavUid);

try
    if yunlink_state(uav).landed
        fprintf('起飞\n');
        yunlink_takeoff(uav, height, 30);
    end
    pos = yunlink_state(uav).position;
    % N×3，每行一个 x y z。
    points = [
        pos.x + 0.25, pos.y, height
        pos.x + 0.25, pos.y + 0.25, height
        ];
    fprintf('航点任务（两点）\n');
    yunlink_waypoints(uav, points, 120);
    disp(yunlink_state(uav).planner);
finally
    if ~yunlink_state(uav).landed
        fprintf('降落\n');
        yunlink_land(uav, 30);
    end
end
fprintf('完成。\n');

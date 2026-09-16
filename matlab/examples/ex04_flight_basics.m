% 04_FLIGHT_BASICS  起飞、机体平移、目标移动、悬停、降落。
% 本示例会发送飞行指令。请只对允许运动的实体运行。

[address, envUav, envUgv] = yunlink_example_target();
uavUid = envUav;
height = 1.0;

client = yunlink_connect(address);
cleanup = onCleanup(@() yunlink_close(client));
uavUid = yunlink_example_pick(client, "sunray.uav", uavUid);
uav = yunlink_vehicle(client, uavUid);

try
    fprintf('1) 起飞\n');
    if yunlink_state(uav).landed
        yunlink_takeoff(uav, height, 30);
    else
        fprintf('已在空中，跳过起飞。\n');
    end
    fprintf('2) 前进\n');
    yunlink_translate(uav, "forward", 0.15, 0.8, 15);
    fprintf('3) 后退\n');
    yunlink_translate(uav, "backward", 0.15, 0.8, 15);
    fprintf('4) 左移\n');
    yunlink_translate(uav, "left", 0.15, 0.5, 15);
    fprintf('5) 右移\n');
    yunlink_translate(uav, "right", 0.15, 0.5, 15);
    fprintf('6) 上升\n');
    yunlink_translate(uav, "up", 0.1, 0.5, 15);
    fprintf('7) 下降\n');
    yunlink_translate(uav, "down", 0.1, 0.5, 15);
    pos = yunlink_state(uav).position;
    fprintf('8) 目标移动\n');
    yunlink_move_to(uav, pos.x + 0.3, pos.y, height, 60);
    fprintf('9) 悬停\n');
    yunlink_hover(uav, 15);
finally
    if ~yunlink_state(uav).landed
        fprintf('10) 降落\n');
        yunlink_land(uav, 30);
    end
end
fprintf('完成。\n');

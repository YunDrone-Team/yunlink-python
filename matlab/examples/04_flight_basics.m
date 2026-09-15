% 04_FLIGHT_BASICS  起飞、机体平移、目标移动、悬停、降落。
% 本示例会发送飞行指令。请只对允许运动的实体运行。

address = "192.168.31.236:9696";
uavUid = "e-f97f96-2-1";
height = 1.0;

client = yunlink_connect(address);
cleanup = onCleanup(@() yunlink_close(client));
uav = yunlink_vehicle(client, uavUid);

try
    disp('1) 起飞');
    disp(yunlink_takeoff(uav, height, 30));
    disp('2) 前进');
    disp(yunlink_translate(uav, "forward", 0.15, 0.8, 15));
    disp('3) 后退');
    disp(yunlink_translate(uav, "backward", 0.15, 0.8, 15));
    disp('4) 左移');
    disp(yunlink_translate(uav, "left", 0.15, 0.5, 15));
    disp('5) 右移');
    disp(yunlink_translate(uav, "right", 0.15, 0.5, 15));
    disp('6) 上升');
    disp(yunlink_translate(uav, "up", 0.1, 0.5, 15));
    disp('7) 下降');
    disp(yunlink_translate(uav, "down", 0.1, 0.5, 15));
    pos = yunlink_state(uav).position;
    disp('8) 目标移动');
    disp(yunlink_move_to(uav, pos.x + 0.3, pos.y, height, 60));
    disp('9) 悬停');
    disp(yunlink_hover(uav, 15));
finally
    if ~yunlink_state(uav).landed
        disp('10) 降落');
        disp(yunlink_land(uav, 30));
    end
end

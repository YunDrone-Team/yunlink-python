% 04_FLIGHT_BASICS  起飞、平移、目标移动、悬停、降落。
%
% 做什么：完整基础飞。会发真实控制指令。只对仿真或允许运动的飞机运行。
% 本步要读：yunlink.env 的 YUNLINK_ADDRESS、YUNLINK_UAV（entity_uid，不是 uav1）。
% 上一步：ex03 确认 fresh=1。
% 不要改本文件中间的变量。

[address, uavUid] = yunlink_example_target();
height = 1.0;

fprintf('本脚本会起飞。周围请空出。\n');
client = yunlink_connect(address);
cleanup = onCleanup(@() yunlink_close(client));
uavUid = yunlink_example_pick(client, "sunray.uav", uavUid);
% attach 之后才会订阅遥测。
uav = yunlink_vehicle(client, uavUid);

try
    fprintf('1) 起飞（已在空中则跳过，避免 INIT 拒绝）\n');
    if yunlink_state(uav).landed
        yunlink_takeoff(uav, height, 30);
    else
        fprintf('已在空中，跳过起飞。\n');
    end
    % 机体轴短时平移。租约结束常为 CANCELLED，不是失败。
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
    % 直控结束后先悬停，让 Planner 回到 WAIT_MISSION，再交航点。
    fprintf('7b) 悬停，准备航点\n');
    yunlink_hover(uav, 15);
    pos = yunlink_state(uav).position;
    fprintf('8) Planner 目标移动\n');
    yunlink_move_to(uav, pos.x + 0.3, pos.y, height, 60);
    fprintf('9) 悬停\n');
    yunlink_hover(uav, 15);
finally
    % 无论中间是否出错，尽量降落。
    if ~yunlink_state(uav).landed
        fprintf('10) 降落\n');
        yunlink_land(uav, 30);
    end
end
fprintf('完成。\n');

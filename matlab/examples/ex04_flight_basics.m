% 04_FLIGHT_BASICS  起飞、机体轴短移、悬停、降落。
%
% 做什么：完整基础飞。会发真实控制指令。只对仿真或允许运动的飞机运行。
% 会不会飞：会。
% 本步要读：yunlink.env 的 YUNLINK_ADDRESS、YUNLINK_UAV（entity_uid，不是 uav1）。
% 上一步：ex03 确认 fresh=1。
% 下一步：ex05 取消，或直接 ex12 全量检查。
% 不要改本文件中间的变量。
%
% 运动量（理想情况，机体轴）：
%   起飞高度 1.0 米。
%   前进/后退：速度 0.15 m/s × 0.8 秒 ≈ 0.12 米。
%   左/右：速度 0.15 m/s × 0.5 秒 ≈ 0.075 米。
%   升/降：速度 0.1 m/s × 0.5 秒 ≈ 0.05 米。
% 周围请空出前后左右各 1 米、头上 2 米。

% 从 yunlink.env 读连接地址和 UAV 的 entity_uid。
[address, uavUid] = yunlink_example_target();
% 起飞目标相对高度，单位米。后面 takeoff 用这个数。
height = 1.0;

fprintf('本脚本会起飞。周围请空出。\n');
% 只连 Bridge（TCP 9696），还不选飞机、不申请控制权。
client = yunlink_connect(address);
% 脚本结束或出错时自动断开，避免占着 Session。
cleanup = onCleanup(@() yunlink_close(client));
% env 没填 UAV 且目录只有一架时，会暂用那一架并提醒你写入 yunlink.env。
uavUid = yunlink_example_pick(client, "sunray.uav", uavUid);
% attach 之后才会订阅遥测。这一行仍不起飞。
uav = yunlink_vehicle(client, uavUid);

try
    fprintf('1) 起飞（已在空中则跳过，避免 INIT 拒绝）\n');
    if yunlink_state(uav).landed
        % 第 2 个参数：相对高度，单位米。这里 1.0 = 飞到约 1 米。
        % 第 3 个参数：最多等 30 秒等起飞结束，不是飞 30 米。
        yunlink_takeoff(uav, height, 30);
    else
        fprintf('已在空中，跳过起飞。\n');
    end
    % 机体轴短时平移。参数是速度和持续时间，不是位移米数。
    % 租约时间到了，结果常为 CANCELLED，这是预期，不是失败。
    fprintf('2) 前进\n');
    % "forward"：机头方向。
    % 0.15：速度，单位 m/s（不是米）。
    % 0.8：持续秒。大约位移 = 0.15 * 0.8 = 0.12 米。
    % 15：等待动作结束的超时秒。
    yunlink_translate(uav, "forward", 0.15, 0.8, 15);
    fprintf('3) 后退\n');
    % 同样 0.15 m/s × 0.8 s ≈ 0.12 米，往机尾方向走回去。
    yunlink_translate(uav, "backward", 0.15, 0.8, 15);
    fprintf('4) 左移\n');
    % 0.15 m/s × 0.5 s ≈ 0.075 米。
    yunlink_translate(uav, "left", 0.15, 0.5, 15);
    fprintf('5) 右移\n');
    % 0.15 m/s × 0.5 s ≈ 0.075 米，往回走。
    yunlink_translate(uav, "right", 0.15, 0.5, 15);
    fprintf('6) 上升\n');
    % 0.1 m/s × 0.5 s ≈ 0.05 米。最高大约 1.05 米。
    yunlink_translate(uav, "up", 0.1, 0.5, 15);
    fprintf('7) 下降\n');
    % 0.1 m/s × 0.5 s ≈ 0.05 米，回到约 1 米。
    yunlink_translate(uav, "down", 0.1, 0.5, 15);
    fprintf('8) 悬停\n');
    % 15：等待悬停完成的超时秒。
    yunlink_hover(uav, 15);
finally
    % 无论中间是否出错，尽量降落。
    if ~yunlink_state(uav).landed
        fprintf('10) 降落\n');
        % 30：等待降落结束的超时秒。
        yunlink_land(uav, 30);
    end
end
fprintf('完成。\n');

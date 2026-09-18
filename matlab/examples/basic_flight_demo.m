% BASIC_FLIGHT_DEMO  精简起飞、位置、悬停、降落。
%
% 做什么：会飞。只对仿真或允许运动的飞机运行。
% 会不会飞：会。这是 ex04 的短版；带注释的完整版请看 ex04_flight_basics。
% 本步要读：yunlink.env 的 YUNLINK_ADDRESS、YUNLINK_UAV。
%
% 起飞高度 1.5 米。随后位置控制到 x=2.0、y=0.0、z=1.5（世界系，单位米）。

[address, uavUid] = yunlink_example_target();
fprintf('本脚本会起飞。\n');
client = yunlink_connect(address);
cleanup = onCleanup(@() yunlink_close(client));
uavUid = yunlink_example_pick(client, "sunray.uav", uavUid);
uav = yunlink_vehicle(client, uavUid);

disp(yunlink_state(uav));
if yunlink_state(uav).landed
    % 1.5：相对高度，单位米。超时用函数默认值 30 秒。
    yunlink_takeoff(uav, 1.5);
end
% 第 2/3/4 个参数：目标 x、y、z，单位米。不是速度。
yunlink_position_control(uav, 2.0, 0.0, 1.5);
yunlink_hover(uav);
% 3：监视 3 秒。print=true 会往命令窗口打状态。
disp(yunlink_monitor(uav, 3, struct('print', true)));
if ~yunlink_state(uav).landed
    yunlink_land(uav);
end
fprintf('完成。\n');

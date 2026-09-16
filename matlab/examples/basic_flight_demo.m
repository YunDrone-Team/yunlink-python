% BASIC_FLIGHT_DEMO  精简起飞、位置、悬停、降落。
%
% 做什么：会飞。只对仿真或允许运动的飞机运行。
% 本步要读：yunlink.env 的 YUNLINK_ADDRESS、YUNLINK_UAV。
% 完整版见 ex04_flight_basics。

[address, uavUid] = yunlink_example_target();
fprintf('本脚本会起飞。\n');
client = yunlink_connect(address);
cleanup = onCleanup(@() yunlink_close(client));
uavUid = yunlink_example_pick(client, "sunray.uav", uavUid);
uav = yunlink_vehicle(client, uavUid);

disp(yunlink_state(uav));
if yunlink_state(uav).landed
    yunlink_takeoff(uav, 1.5);
end
yunlink_position_control(uav, 2.0, 0.0, 1.5);
yunlink_hover(uav);
disp(yunlink_monitor(uav, 3, struct('print', true)));
if ~yunlink_state(uav).landed
    yunlink_land(uav);
end
fprintf('完成。\n');

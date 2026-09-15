% BASIC_FLIGHT_DEMO  精简飞行示例。
% 本示例会发送飞行指令。请只对允许运动的实体运行。
% 请把地址和 entity_uid 换成 ex01_discover.m 确认过的值。
client = yunlink_connect("192.168.31.236:9696");
cleanup = onCleanup(@() yunlink_close(client));
uav = yunlink_vehicle(client, "e-f97f96-2-1");

disp(yunlink_state(uav));
yunlink_takeoff(uav, 1.5);
yunlink_position_control(uav, 2.0, 0.0, 1.5);
yunlink_hover(uav);
disp(yunlink_monitor(uav, 3, struct('print', true)));
yunlink_land(uav);

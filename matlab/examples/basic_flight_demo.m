% BASIC_FLIGHT_DEMO  精简飞行示例。
% 本示例会发送飞行指令。请只对允许运动的实体运行。
% 请把地址和 entity_uid 换成 ex01_discover.m 确认过的值。
[address, envUav, envUgv] = yunlink_example_target();
uavUid = envUav;
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

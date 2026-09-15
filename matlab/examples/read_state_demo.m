% READ_STATE_DEMO  连接并打印 UAV 状态。本示例不发送飞行指令。
% 请把地址和 entity_uid 换成 ex01_discover.m 确认过的值。
client = yunlink_connect("192.168.31.236:9696");
cleanup = onCleanup(@() yunlink_close(client));
uav = yunlink_vehicle(client, "e-f97f96-2-1");

state = yunlink_state(uav);
disp(state.uavId);
disp(state.position);
disp(state.velocity);
disp(state.batteryPercent);
disp(state.px4Mode);
disp(state.controlModeName);
disp(state.movementMode);
disp(state.armed);
disp(state.disarmed);
disp(state.landed);
disp(state.localization);

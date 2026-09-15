% READ_STATE_DEMO  连接并打印 UAV 状态。本示例不发送飞行指令。
% 请把地址和 entity_uid 换成 ex01_discover.m 确认过的值。
address = string(getenv('YUNLINK_ADDRESS'));
if strlength(address) == 0
    address = "192.168.10.10:9696";
end
uavUid = string(getenv('YUNLINK_UAV'));
if strlength(uavUid) == 0
    uavUid = "e-89c423-2-1";
end
client = yunlink_connect(address);
cleanup = onCleanup(@() yunlink_close(client));
uav = yunlink_vehicle(client, uavUid);

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

% READ_STATE_DEMO  连接并打印一架 UAV 状态。
%
% 做什么：只读，不飞。
% 本步要读：yunlink.env 的 YUNLINK_ADDRESS、YUNLINK_UAV（entity_uid）。
% 上一步：ex01/ex02 表的第一列。

[address, uavUid] = yunlink_example_target();
client = yunlink_connect(address);
cleanup = onCleanup(@() yunlink_close(client));
uavUid = yunlink_example_pick(client, "sunray.uav", uavUid);
uav = yunlink_vehicle(client, uavUid);

state = yunlink_state(uav);
fprintf('entity_uid=%s  （这就是 YUNLINK_UAV 应填的值）\n', state.uavId);
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

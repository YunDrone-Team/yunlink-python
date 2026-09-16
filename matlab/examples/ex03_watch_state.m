% 03_WATCH_STATE  attach 一架 UAV 并打印状态。本示例不发送飞行指令。

[address, envUav, envUgv] = yunlink_example_target();
uavUid = envUav;

client = yunlink_connect(address);
cleanup = onCleanup(@() yunlink_close(client));
uavUid = yunlink_example_pick(client, "sunray.uav", uavUid);
uav = yunlink_vehicle(client, uavUid);
pause(0.5);
state = yunlink_state(uav);
disp(state.uavId);
disp(state.position);
disp(state.velocity);
disp(state.batteryPercent);
disp(state.px4Mode);
disp(state.armed);
disp(state.landed);
disp(state.fresh);
disp(state.localization);

% 03_WATCH_STATE  attach 一架 UAV 并打印状态。本示例不发送飞行指令。

address = "192.168.31.236:9696";
uavUid = "e-f97f96-2-1";

client = yunlink_connect(address);
cleanup = onCleanup(@() yunlink_close(client));
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

% READ_STATE_DEMO Connect and print UAV state. This example does not send flight commands.
client = yunlink_connect("192.168.31.236:9696");
cleanup = onCleanup(@() yunlink_close(client));
uav = yunlink_vehicle(client, "uav1");

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

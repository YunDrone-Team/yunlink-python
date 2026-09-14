% 07_UGV_CONTROL  MovePoint, velocity lease, and Hold for a UGV.
% This example sends UGV motion commands.

address = "192.168.31.236:9696";
ugvUid = "e-f97f96-3-1";

client = yunlink_connect(address);
cleanup = onCleanup(@() yunlink_close(client));
ugv = yunlink_ugv(client, ugvUid);
disp(yunlink_ugv_state(ugv));
start = yunlink_ugv_state(ugv).position;
disp(yunlink_ugv_move_to(ugv, start.x + 0.3, start.y, 45));
disp(yunlink_ugv_velocity(ugv, 0.1, 0.5, 15));
disp(yunlink_ugv_hold(ugv, 15));
disp(yunlink_ugv_state(ugv));

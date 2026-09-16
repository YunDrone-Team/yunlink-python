% 07_UGV_CONTROL  无人车点位移动、速度控制和 Hold。
% 本示例会发送无人车运动指令。

[address, envUav, envUgv] = yunlink_example_target();
ugvUid = envUgv;

client = yunlink_connect(address);
cleanup = onCleanup(@() yunlink_close(client));
ugvUid = yunlink_example_pick(client, "sunray.ugv", ugvUid);
ugv = yunlink_ugv(client, ugvUid);
disp(yunlink_ugv_state(ugv));
start = yunlink_ugv_state(ugv).position;
fprintf('点位移动\n');
yunlink_ugv_move_to(ugv, start.x + 0.3, start.y, 45);
fprintf('速度控制\n');
yunlink_ugv_velocity(ugv, 0.1, 0.5, 15);
fprintf('Hold\n');
yunlink_ugv_hold(ugv, 15);
disp(yunlink_ugv_state(ugv));
fprintf('完成。\n');

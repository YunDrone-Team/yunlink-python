% 07_UGV_CONTROL  无人车点位、速度、Hold。
%
% 做什么：会发无人车运动指令。
% 本步要读：yunlink.env 的 YUNLINK_ADDRESS、YUNLINK_UGV（entity_uid，不是 ugv1）。
% 上一步：ex02 表里类型为 sunray.ugv 的那一行。

[address, ~, ugvUid] = yunlink_example_target();

fprintf('本脚本会移动无人车。\n');
client = yunlink_connect(address);
cleanup = onCleanup(@() yunlink_close(client));
ugvUid = yunlink_example_pick(client, "sunray.ugv", ugvUid);
% attach UGV，不飞。
ugv = yunlink_ugv(client, ugvUid);

% frame_id 为空时不要 move_to，等状态新鲜。
pause(0.5);
disp(yunlink_ugv_state(ugv));
start = yunlink_ugv_state(ugv).position;
fprintf('点位移动 +0.3m\n');
yunlink_ugv_move_to(ugv, start.x + 0.3, start.y, 45);
fprintf('短时速度租约（结束常为 CANCELLED）\n');
yunlink_ugv_velocity(ugv, 0.1, 0.5, 15);
fprintf('Hold\n');
yunlink_ugv_hold(ugv, 15);
disp(yunlink_ugv_state(ugv));
fprintf('完成。\n');

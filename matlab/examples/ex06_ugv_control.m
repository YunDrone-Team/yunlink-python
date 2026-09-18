% 06_UGV_CONTROL  无人车点位、速度、Hold。
%
% 做什么：会发无人车运动指令。
% 会不会飞：不会飞；会走。
% 本步要读：yunlink.env 的 YUNLINK_ADDRESS、YUNLINK_UGV（entity_uid，不是 ugv1）。
% 上一步：ex02 表里类型为 sunray.ugv 的那一行。
%
% 点位：当前 x 再加 0.3 米。速度：0.1 m/s × 0.5 秒 ≈ 0.05 米。

[address, ~, ugvUid] = yunlink_example_target();

fprintf('本脚本会移动无人车。\n');
client = yunlink_connect(address);
cleanup = onCleanup(@() yunlink_close(client));
% 没填 YUNLINK_UGV 且只有一台无人车时，暂用那一台。
ugvUid = yunlink_example_pick(client, "sunray.ugv", ugvUid);
% attach UGV，订阅状态。不飞。
ugv = yunlink_ugv(client, ugvUid);

% frame_id 为空时不要 move_to，等半秒让状态新鲜。
pause(0.5);
disp(yunlink_ugv_state(ugv));
% 当前平面位置，单位米。
start = yunlink_ugv_state(ugv).position;
fprintf('点位移动 +0.3m\n');
% 第 2、3 个参数：目标 x/y，单位米。这里 x 加 0.3 米，y 不变。
% 第 4 个参数：最多等 45 秒走到点，不是走 45 米。
yunlink_ugv_move_to(ugv, start.x + 0.3, start.y, 45);
fprintf('短时速度租约（结束常为 CANCELLED）\n');
% 第 2 个：前进速度 m/s（不是米）。
% 第 3 个：持续秒。大约位移 = 0.1 * 0.5 = 0.05 米。
% 第 4 个：等待超时秒。
yunlink_ugv_velocity(ugv, 0.1, 0.5, 15);
fprintf('Hold\n');
% 15：等待 Hold 完成的超时秒。
yunlink_ugv_hold(ugv, 15);
disp(yunlink_ugv_state(ugv));
fprintf('完成。\n');

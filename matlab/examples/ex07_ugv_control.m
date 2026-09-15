% 07_UGV_CONTROL  无人车点位移动、速度控制和 Hold。
% 本示例会发送无人车运动指令。

address = string(getenv('YUNLINK_ADDRESS'));
if strlength(address) == 0
    address = "192.168.10.10:9696";
end
ugvUid = string(getenv('YUNLINK_UGV'));
if strlength(ugvUid) == 0
    ugvUid = "e-89c423-3-1";
end

client = yunlink_connect(address);
cleanup = onCleanup(@() yunlink_close(client));
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

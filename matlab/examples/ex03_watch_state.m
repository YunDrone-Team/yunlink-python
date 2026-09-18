% 03_WATCH_STATE  attach 一架 UAV，只读状态。
%
% 做什么：订阅遥测并打印。不飞。
% 会不会飞：不会。
% 本步要读：yunlink.env 的 YUNLINK_ADDRESS、YUNLINK_UAV（entity_uid）。
% 上一步：ex02 表中「entity_uid」那一列写入 YUNLINK_UAV=。
% 下一步：fresh=1 之后才能跑 ex04（会飞）。
% 不要改本文件中间的变量。

% 地址和 UAV entity_uid 都来自 yunlink.env，不要在这里手填。
[address, uavUid] = yunlink_example_target();

% 连接 Bridge，仍未选飞机。
client = yunlink_connect(address);
cleanup = onCleanup(@() yunlink_close(client));

% 若 env 为空且目录只有一台 UAV，会暂用它并提醒你写入 yunlink.env。
uavUid = yunlink_example_pick(client, "sunray.uav", uavUid);

% 这一行才会 attach 并订阅状态，仍不发起飞、不抢地面站控制权。
uav = yunlink_vehicle(client, uavUid);
% 等半秒，让第一包遥测到。
pause(0.5);

% MATLAB 结构体。fresh=0 表示状态太旧，不要拿去飞。
state = yunlink_state(uav);
fprintf('entity_uid=%s fresh=%d landed=%d z=%.3f\n', ...
    state.uavId, state.fresh, state.landed, state.position.z);
% position 单位米；velocity 单位 m/s；batteryPercent 是百分数。
disp(state.position);
disp(state.velocity);
disp(state.batteryPercent);
disp(state.px4Mode);
% armed/landed 只是状态位，没有对应的「解锁函数」。
disp(state.armed);
disp(state.landed);
disp(state.fresh);
disp(state.localization);
fprintf('只读完成。飞行从 ex04_flight_basics 开始，会发真实指令。\n');

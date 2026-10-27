% 13_ACCELERATION_COMPENSATION 运行一次 MATLAB 加速度补偿闭环示例。
%
% 会执行：起飞到约 1 m -> 发送 NED 加速度样本 -> 取消补偿 -> 降落。
% 加速度补偿不负责起飞、降落或位置控制；输入是世界 NED、m/s^2、不含重力。
% 运行前请先完成 ex00_setup，并在 yunlink.env 中填写地址和 UAV entity_uid。

env = yunlink_load_example_env();
if strlength(env.address) == 0 || strlength(env.uav) == 0
    error('yunlink:MissingExampleTarget', ...
        '请先在 examples/yunlink.env 中填写 YUNLINK_ADDRESS 和 YUNLINK_UAV。');
end

client = yunlink_connect(env.address);
cleanup = onCleanup(@() yunlink_close(client)); %#ok<NASGU>
uav = yunlink_vehicle(client, env.uav);

state = yunlink_state(uav);
fprintf('UAV %s: landed=%d fresh=%d controller=%d\n', ...
    state.uavId, state.landed, state.fresh, state.controllerType);

yunlink_takeoff(uav, 1.0, 30);
pause(0.5);

channel = yunlink_acceleration_compensation(uav);
channelCleanup = onCleanup(@() close_acceleration(channel)); %#ok<NASGU>
fprintf('Sending 100 Hz NED samples for 1.5 seconds...\n');
started = tic;
while toc(started) < 1.5
    % 示例输入：NED 北向 0.05 m/s^2、东向 0.02 m/s^2、向下为 0。
    yunlink_acceleration_update(channel, 0.05, 0.02, 0.0);
    pause(0.01);
end

yunlink_acceleration_cancel(channel);
clear channelCleanup
yunlink_land(uav, 30);
fprintf('Acceleration compensation example completed.\n');

function close_acceleration(channel)
try
    yunlink_acceleration_cancel(channel);
catch exception
    warning('yunlink:AccelerationCleanup', '补偿清理失败：%s', exception.message);
end
end

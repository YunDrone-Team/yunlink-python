% 08_ERRORS  演示连接失败、实体不存在和动作超时。
% 本示例可能发出一次预期会超时的起飞。

[address, envUav, envUgv] = yunlink_example_target();
uavUid = envUav;

try
    client = yunlink_connect(address);
    cleanup = onCleanup(@() yunlink_close(client));
    try
        yunlink_vehicle(client, "does-not-exist");
    catch exception
        fprintf('实体错误：%s\n', exception.message);
    end
    uavUid = yunlink_example_pick(client, "sunray.uav", uavUid);
    uav = yunlink_vehicle(client, uavUid);
    try
        yunlink_takeoff(uav, 1.0, 0.001);
    catch exception
        fprintf('超时或被拒绝：%s\n', exception.message);
    end
catch exception
    fprintf('连接错误：%s\n', exception.message);
end

% 08_ERRORS  演示连接失败、实体不存在和动作超时。
% 本示例可能发出一次预期会超时的起飞。

address = string(getenv('YUNLINK_ADDRESS'));
if strlength(address) == 0
    address = "192.168.10.10:9696";
end
uavUid = string(getenv('YUNLINK_UAV'));
if strlength(uavUid) == 0
    uavUid = "e-89c423-2-1";
end

try
    client = yunlink_connect(address);
    cleanup = onCleanup(@() yunlink_close(client));
    try
        yunlink_vehicle(client, "does-not-exist");
    catch exception
        fprintf('实体错误：%s\n', exception.message);
    end
    uav = yunlink_vehicle(client, uavUid);
    try
        yunlink_takeoff(uav, 1.0, 0.001);
    catch exception
        fprintf('超时或被拒绝：%s\n', exception.message);
    end
catch exception
    fprintf('连接错误：%s\n', exception.message);
end

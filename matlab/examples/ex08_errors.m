% 08_ERRORS  看错误长什么样：不存在的设备和过短超时。
%
% 做什么：可能发一次预期会失败的起飞。
% 本步要读：yunlink.env 的 YUNLINK_ADDRESS、YUNLINK_UAV。

[address, uavUid] = yunlink_example_target();

try
    client = yunlink_connect(address);
    cleanup = onCleanup(@() yunlink_close(client));
    try
        % 故意用不存在的 entity_uid。
        yunlink_vehicle(client, "does-not-exist");
    catch exception
        fprintf('实体错误（预期）：%s\n', exception.message);
    end
    uavUid = yunlink_example_pick(client, "sunray.uav", uavUid);
    uav = yunlink_vehicle(client, uavUid);
    try
        % 超时设得很短，用来看超时信息。
        yunlink_takeoff(uav, 1.0, 0.001);
    catch exception
        fprintf('超时或被拒绝（预期）：%s\n', exception.message);
    end
catch exception
    fprintf('连接错误：%s\n', exception.message);
end

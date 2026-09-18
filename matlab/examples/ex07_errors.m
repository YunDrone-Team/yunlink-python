% 07_ERRORS  看错误长什么样：不存在的设备和过短超时。
%
% 做什么：故意触发失败，学会读报错。可能发一次预期会失败的起飞。
% 会不会飞：正常情况下起飞会立刻超时/被拒，飞机不该真正飞起来。
% 本步要读：yunlink.env 的 YUNLINK_ADDRESS、YUNLINK_UAV。
% 上一步：ex02/ex03。下一步：ex08 或多机只读。

[address, uavUid] = yunlink_example_target();

try
    client = yunlink_connect(address);
    cleanup = onCleanup(@() yunlink_close(client));
    try
        % 故意用不存在的 entity_uid。成功 attach 反而不对。
        yunlink_vehicle(client, "does-not-exist");
    catch exception
        fprintf('实体错误（预期）：%s\n', exception.message);
    end
    uavUid = yunlink_example_pick(client, "sunray.uav", uavUid);
    uav = yunlink_vehicle(client, uavUid);
    try
        % 第 2 个参数 1.0：相对高度米（如果真飞起来会到 1 米）。
        % 第 3 个参数 0.001：超时秒，故意设得很短，用来看超时信息。
        yunlink_takeoff(uav, 1.0, 0.001);
    catch exception
        fprintf('超时或被拒绝（预期）：%s\n', exception.message);
    end
catch exception
    fprintf('连接错误：%s\n', exception.message);
end

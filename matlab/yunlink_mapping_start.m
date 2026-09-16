function result = yunlink_mapping_start(device, timeout)
%YUNLINK_MAPPING_START 开始 Livox 点云累积。
%   UAV 和 UGV 都可以调用。timeout 默认 8 秒。
if nargin < 2
    timeout = 8;
end
result = device.start_mapping(pyargs('timeout', double(timeout)));
end

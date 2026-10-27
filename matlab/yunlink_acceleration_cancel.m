function result = yunlink_acceleration_cancel(channel, timeout)
%YUNLINK_ACCELERATION_CANCEL 清零并关闭加速度补偿通道。
%   只清除补偿，不调用 Hover，也不取消原有飞行任务。
if nargin < 2
    timeout = 3;
end
result = channel.cancel(pyargs('timeout', double(timeout)));
end

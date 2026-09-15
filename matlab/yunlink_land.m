function result = yunlink_land(vehicle, timeout)
%YUNLINK_LAND 降落并等待动作完成。
%   timeout 默认 30 秒。落地状态是异步上报的，随后可用 yunlink_state 再确认 landed。
if nargin < 2
    timeout = 30;
end
result = vehicle.land(pyargs('timeout', double(timeout)));
end

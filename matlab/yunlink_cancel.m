function result = yunlink_cancel(vehicle, timeout)
%YUNLINK_CANCEL 取消当前动作或 Planner 任务。
%   对应 Python Vehicle.cancel。timeout 默认 15 秒。
if nargin < 2
    timeout = 15;
end
result = vehicle.cancel(double(timeout));
end

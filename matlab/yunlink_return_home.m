function result = yunlink_return_home(vehicle, timeout)
%YUNLINK_RETURN_HOME 请求 Planner 返航。
%   必须显式调用，不会在脚本结束时自动返航。
if nargin < 2
    timeout = 120;
end
result = vehicle.return_home(pyargs('timeout', double(timeout)));
end

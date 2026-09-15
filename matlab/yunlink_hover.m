function result = yunlink_hover(vehicle, timeout)
%YUNLINK_HOVER 进入悬停。
%   用于取消移动或起飞后稳住。timeout 默认 15 秒。
if nargin < 2
    timeout = 15;
end
result = vehicle.hover(pyargs('timeout', double(timeout)));
end

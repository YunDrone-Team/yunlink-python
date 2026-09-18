function result = yunlink_hover(vehicle, timeout)
%YUNLINK_HOVER 进入悬停。
%   第 2 个参数 timeout：等待悬停完成的超时秒，默认 15。不是悬停高度。
%   用于取消移动或起飞后稳住。
if nargin < 2
    timeout = 15;
end
result = vehicle.hover(pyargs('timeout', double(timeout)));
end

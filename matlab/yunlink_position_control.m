function result = yunlink_position_control(vehicle, x, y, z, yaw_rad, timeout)
%YUNLINK_POSITION_CONTROL 直接位置控制，不走 Planner 航线。
%   第 2/3/4 个参数 x、y、z：目标位置，单位米。不是速度。
%   yaw_rad 默认 0 弧度，timeout 默认 120 秒。会发送飞行指令。
if nargin < 5
    yaw_rad = 0;
end
if nargin < 6
    timeout = 120;
end
result = vehicle.position_control( ...
    double(x), double(y), double(z), double(yaw_rad), ...
    pyargs('timeout', double(timeout)));
end

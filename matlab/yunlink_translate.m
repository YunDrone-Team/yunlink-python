function result = yunlink_translate(vehicle, direction, speed_mps, duration_s, timeout)
%YUNLINK_TRANSLATE 机体轴短时平移：forward/backward/left/right/up/down。
%   第 3 个参数 speed_mps：速度，单位 m/s，不是米。默认 0.15。
%   第 4 个参数 duration_s：持续秒。默认 0.8。大约位移 = 速度 × 时间。
%   第 5 个参数 timeout：等待动作结束的超时秒。默认 15。
%   例如 forward、0.15、0.8 大约走 0.12 米。租约结束常为 CANCELLED，不是失败。
if nargin < 3
    speed_mps = 0.15;
end
if nargin < 4
    duration_s = 0.8;
end
if nargin < 5
    timeout = 15;
end
args = pyargs('duration_s', double(duration_s), 'timeout', double(timeout));
switch lower(string(direction))
    case "forward"
        result = vehicle.forward(double(speed_mps), args);
    case "backward"
        result = vehicle.backward(double(speed_mps), args);
    case "left"
        result = vehicle.left(double(speed_mps), args);
    case "right"
        result = vehicle.right(double(speed_mps), args);
    case "up"
        result = vehicle.up(double(speed_mps), args);
    case "down"
        result = vehicle.down(double(speed_mps), args);
    otherwise
        error('yunlink:UnsupportedCommand', 'Unsupported translate direction: %s', direction);
end
end

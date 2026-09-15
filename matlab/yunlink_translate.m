function result = yunlink_translate(vehicle, direction, speed_mps, duration_s, timeout)
%YUNLINK_TRANSLATE 机体轴短时平移：forward/backward/left/right/up/down。
%   默认速度 0.15 m/s、持续 0.8 s。用于基础飞行动作演示。
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

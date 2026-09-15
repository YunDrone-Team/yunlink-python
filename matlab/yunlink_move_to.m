function result = yunlink_move_to(vehicle, x, y, z, timeout)
%YUNLINK_MOVE_TO Planner 单目标移动，坐标系与当前里程计一致。
%   timeout 默认 60 秒。需要飞机已起飞且状态新鲜。
if nargin < 5
    timeout = 60;
end
result = vehicle.move_to(double(x), double(y), double(z), pyargs('timeout', double(timeout)));
end

function result = yunlink_waypoint(vehicle, x, y, z, timeout)
%YUNLINK_WAYPOINT 单个 Planner 航点，完成后悬停。
if nargin < 5
    timeout = 120;
end
result = vehicle.waypoint(double(x), double(y), double(z), pyargs('timeout', double(timeout)));
end

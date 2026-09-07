function result = yunlink_waypoint(vehicle, x, y, z, timeout)
%YUNLINK_WAYPOINT Execute one Planner waypoint and finish in hover.
if nargin < 5
    timeout = 120;
end
result = vehicle.waypoint(double(x), double(y), double(z), pyargs('timeout', double(timeout)));
end

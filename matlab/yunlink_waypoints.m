function result = yunlink_waypoints(vehicle, points, timeout)
%YUNLINK_WAYPOINTS 多航点 Planner 任务。
%   points 为 N×3 的 x/y/z。会发送飞行指令。
if nargin < 3
    timeout = 120;
end
sdk = py.importlib.import_module("yunlink_python");
wps = py.list();
for index = 1:size(points, 1)
    wps.append(sdk.Waypoint(double(points(index, 1)), double(points(index, 2)), double(points(index, 3))));
end
result = vehicle.waypoints(wps, pyargs('timeout', double(timeout)));
end

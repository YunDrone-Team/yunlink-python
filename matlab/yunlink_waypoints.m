function result = yunlink_waypoints(vehicle, points, timeout)
%YUNLINK_WAYPOINTS Execute a Planner multi-waypoint mission.
%   points is an N-by-3 matrix of x, y, z.
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

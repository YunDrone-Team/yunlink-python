function result = yunlink_position_control(vehicle, x, y, z, yaw_rad, timeout)
%YUNLINK_POSITION_CONTROL Send a direct position action.
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

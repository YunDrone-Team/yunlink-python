function result = yunlink_move_to(vehicle, x, y, z, timeout)
%YUNLINK_MOVE_TO Fly to a position in the current odometry frame.
if nargin < 5
    timeout = 60;
end
result = vehicle.move_to(double(x), double(y), double(z), pyargs('timeout', double(timeout)));
end

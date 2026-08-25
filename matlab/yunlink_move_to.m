function result = yunlink_move_to(vehicle, x, y, z)
%YUNLINK_MOVE_TO Fly to a position in the current odometry frame.
result = vehicle.move_to(double(x), double(y), double(z));
end

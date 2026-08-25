function result = yunlink_waypoint(vehicle, x, y, z)
%YUNLINK_WAYPOINT Execute one Planner waypoint and finish in hover.
result = vehicle.waypoint(double(x), double(y), double(z));
end

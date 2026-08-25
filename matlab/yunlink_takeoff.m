function result = yunlink_takeoff(vehicle, height_m)
%YUNLINK_TAKEOFF Take off to a relative height in metres.
result = vehicle.takeoff(double(height_m));
end

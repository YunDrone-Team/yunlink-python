function result = yunlink_takeoff(vehicle, height_m, timeout)
%YUNLINK_TAKEOFF Take off to a relative height in metres.
if nargin < 3
    timeout = 30;
end
result = vehicle.takeoff(double(height_m), pyargs('timeout', double(timeout)));
end

function result = yunlink_land(vehicle, timeout)
%YUNLINK_LAND Land the UAV.
if nargin < 2
    timeout = 30;
end
result = vehicle.land(pyargs('timeout', double(timeout)));
end

function result = yunlink_hover(vehicle, timeout)
%YUNLINK_HOVER Enter hover.
if nargin < 2
    timeout = 15;
end
result = vehicle.hover(pyargs('timeout', double(timeout)));
end

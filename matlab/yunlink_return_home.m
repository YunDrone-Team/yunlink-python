function result = yunlink_return_home(vehicle, timeout)
%YUNLINK_RETURN_HOME Request the current Planner return-home task.
if nargin < 2
    timeout = 120;
end
result = vehicle.return_home(pyargs('timeout', double(timeout)));
end

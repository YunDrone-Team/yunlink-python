function result = yunlink_cancel(vehicle, timeout)
%YUNLINK_CANCEL Cancel the latest pending action or the current Planner task.
if nargin < 2
    timeout = 15;
end
result = vehicle.cancel(double(timeout));
end

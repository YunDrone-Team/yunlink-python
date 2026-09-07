function result = yunlink_emergency_lock(vehicle, confirmed, timeout)
%YUNLINK_EMERGENCY_LOCK Request an explicitly confirmed emergency lock.
if nargin < 2 || ~logical(confirmed)
    error('yunlink:ConfirmationRequired', ...
        'Emergency lock requires an explicit true confirmation.');
end
if nargin < 3
    timeout = 20;
end
result = vehicle.emergency_lock(pyargs('confirm', true, 'timeout', double(timeout)));
end

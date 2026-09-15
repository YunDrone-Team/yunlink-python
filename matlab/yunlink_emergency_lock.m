function result = yunlink_emergency_lock(vehicle, confirmed, timeout)
%YUNLINK_EMERGENCY_LOCK 紧急上锁。第二个参数必须为 true，防止误触。
if nargin < 2 || ~logical(confirmed)
    error('yunlink:ConfirmationRequired', ...
        'Emergency lock requires an explicit true confirmation.');
end
if nargin < 3
    timeout = 20;
end
result = vehicle.emergency_lock(pyargs('confirm', true, 'timeout', double(timeout)));
end

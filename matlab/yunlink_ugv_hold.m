function result = yunlink_ugv_hold(ugv, timeout)
%YUNLINK_UGV_HOLD Hold the UGV at the current pose.
if nargin < 2
    timeout = 15;
end
result = ugv.hold(double(timeout));
end

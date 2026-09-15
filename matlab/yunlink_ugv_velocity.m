function result = yunlink_ugv_velocity(ugv, vx, duration_s, timeout)
%YUNLINK_UGV_VELOCITY 无人车短时速度租约。到期后常见 CANCELLED。
if nargin < 3
    duration_s = 1.0;
end
if nargin < 4
    timeout = 15;
end
result = ugv.velocity(double(vx), pyargs('duration_s', double(duration_s), 'timeout', double(timeout)));
end

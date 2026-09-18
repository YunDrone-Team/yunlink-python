function result = yunlink_ugv_velocity(ugv, vx, duration_s, timeout)
%YUNLINK_UGV_VELOCITY 无人车短时速度租约。到期后常见 CANCELLED。
%   第 2 个参数 vx：前进速度，单位 m/s，不是米。
%   第 3 个参数 duration_s：持续秒。大约位移 = vx × duration_s。
%   第 4 个参数 timeout：等待超时秒，默认 15。
if nargin < 3
    duration_s = 1.0;
end
if nargin < 4
    timeout = 15;
end
result = ugv.velocity(double(vx), pyargs('duration_s', double(duration_s), 'timeout', double(timeout)));
end

function result = yunlink_takeoff(vehicle, height_m, timeout)
%YUNLINK_TAKEOFF 相对高度起飞，单位米。
%   会申请控制权并发送起飞。若飞机已在空中，飞控可能拒绝（INIT）。
%   timeout 默认 30 秒，等待动作结束。
if nargin < 3
    timeout = 30;
end
result = vehicle.takeoff(double(height_m), pyargs('timeout', double(timeout)));
end

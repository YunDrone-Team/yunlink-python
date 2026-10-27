function channel = yunlink_acceleration_compensation(vehicle, ax, ay, az)
%YUNLINK_ACCELERATION_COMPENSATION 打开世界 NED 加速度补偿通道。
%   channel = yunlink_acceleration_compensation(vehicle)
%   channel = yunlink_acceleration_compensation(vehicle, ax, ay, az)
%
%   输入单位为 m/s^2，坐标为世界 NED（北、东、下），不含重力。
%   该通道只叠加已有位置/速度参考，不负责起飞、降落或位置控制。
%   返回值是 Python AccelerationControl 对象，交给
%   yunlink_acceleration_update / yunlink_acceleration_cancel 使用。
if nargin < 2
    ax = 0;
end
if nargin < 3
    ay = 0;
end
if nargin < 4
    az = 0;
end
channel = vehicle.acceleration_compensation(double(ax), double(ay), double(az));
end

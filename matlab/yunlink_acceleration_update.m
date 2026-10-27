function yunlink_acceleration_update(channel, ax, ay, az)
%YUNLINK_ACCELERATION_UPDATE 发送一个新的 NED 加速度补偿样本。
%   建议算法循环约 100 Hz 调用；超过 300 ms 没有新样本会自动过期。
%   每次调用只发送当前样本，不会在后台自动重发。
channel.update(double(ax), double(ay), double(az));
end

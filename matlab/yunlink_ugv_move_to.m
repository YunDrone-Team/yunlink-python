function result = yunlink_ugv_move_to(ugv, x, y, timeout)
%YUNLINK_UGV_MOVE_TO 无人车平面点位移动。
%   第 2、3 个参数 x、y：目标位置，单位米。
%   第 4 个参数 timeout：等待走到点的超时秒，默认 60。不是走 60 米。
if nargin < 4
    timeout = 60;
end
result = ugv.move_to(double(x), double(y), pyargs('timeout', double(timeout)));
end

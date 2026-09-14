function result = yunlink_ugv_move_to(ugv, x, y, timeout)
%YUNLINK_UGV_MOVE_TO Move a UGV to a planar target.
if nargin < 4
    timeout = 60;
end
result = ugv.move_to(double(x), double(y), pyargs('timeout', double(timeout)));
end

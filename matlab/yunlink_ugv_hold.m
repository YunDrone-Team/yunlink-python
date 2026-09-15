function result = yunlink_ugv_hold(ugv, timeout)
%YUNLINK_UGV_HOLD 无人车在当前位姿保持。
if nargin < 2
    timeout = 15;
end
result = ugv.hold(double(timeout));
end

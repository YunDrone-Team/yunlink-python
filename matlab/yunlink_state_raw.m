function state = yunlink_state_raw(vehicle)
%YUNLINK_STATE_RAW 返回底层 Python VehicleState，一般用 yunlink_state 即可。
state = vehicle.state;
end

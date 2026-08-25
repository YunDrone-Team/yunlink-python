function result = yunlink_cancel(vehicle)
%YUNLINK_CANCEL Cancel the latest pending action, or hover if none is pending.
result = vehicle.cancel();
end

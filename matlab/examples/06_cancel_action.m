% 06_CANCEL_ACTION  Start a move, cancel it, then hover and land.
% This example sends flight commands.

address = "192.168.31.236:9696";
uavUid = "e-f97f96-2-1";
height = 1.0;

client = yunlink_connect(address);
cleanup = onCleanup(@() yunlink_close(client));
uav = yunlink_vehicle(client, uavUid);

try
    disp(yunlink_takeoff(uav, height, 30));
    pos = yunlink_state(uav).position;
    handle = uav.move_to(pos.x + 2.0, pos.y, height, pyargs('timeout', 60, 'wait', false));
    pause(0.4);
    disp(yunlink_cancel(uav, 15));
    disp(handle);
    disp(yunlink_hover(uav, 15));
finally
    if ~yunlink_state(uav).landed
        disp(yunlink_land(uav, 30));
    end
end

% 04_FLIGHT_BASICS  Takeoff, body-frame nudges, move_to, hover, land.
% This example sends flight commands. Use a vehicle that is allowed to move.

address = "192.168.31.236:9696";
uavUid = "e-f97f96-2-1";
height = 1.0;

client = yunlink_connect(address);
cleanup = onCleanup(@() yunlink_close(client));
uav = yunlink_vehicle(client, uavUid);

try
    disp('1) takeoff');
    disp(yunlink_takeoff(uav, height, 30));
    disp('2) forward');
    disp(yunlink_translate(uav, "forward", 0.15, 0.8, 15));
    disp('3) backward');
    disp(yunlink_translate(uav, "backward", 0.15, 0.8, 15));
    disp('4) left');
    disp(yunlink_translate(uav, "left", 0.15, 0.5, 15));
    disp('5) right');
    disp(yunlink_translate(uav, "right", 0.15, 0.5, 15));
    disp('6) up');
    disp(yunlink_translate(uav, "up", 0.1, 0.5, 15));
    disp('7) down');
    disp(yunlink_translate(uav, "down", 0.1, 0.5, 15));
    pos = yunlink_state(uav).position;
    disp('8) move_to');
    disp(yunlink_move_to(uav, pos.x + 0.3, pos.y, height, 60));
    disp('9) hover');
    disp(yunlink_hover(uav, 15));
finally
    if ~yunlink_state(uav).landed
        disp('10) land');
        disp(yunlink_land(uav, 30));
    end
end

% BASIC_FLIGHT_DEMO Minimal YunLink Sunray MATLAB demonstration.
% This example sends flight commands. Use a vehicle that is allowed to move.
% Replace the address and entity_uid with values from Python examples/01_discover.py.
client = yunlink_connect("192.168.31.236:9696");
cleanup = onCleanup(@() yunlink_close(client));
uav = yunlink_vehicle(client, "e-f97f96-2-1");

disp(yunlink_state(uav));
yunlink_takeoff(uav, 1.5);
yunlink_position_control(uav, 2.0, 0.0, 1.5);
yunlink_hover(uav);
disp(yunlink_monitor(uav, 3, struct('print', true)));
yunlink_land(uav);

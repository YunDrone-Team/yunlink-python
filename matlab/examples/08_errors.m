% 08_ERRORS  Show connection, missing-entity, and timeout handling.
% This example may send a short takeoff that is expected to time out.

address = "192.168.31.236:9696";
uavUid = "e-f97f96-2-1";

try
    client = yunlink_connect(address);
    cleanup = onCleanup(@() yunlink_close(client));
    try
        yunlink_vehicle(client, "does-not-exist");
    catch exception
        fprintf('entity error: %s\n', exception.message);
    end
    uav = yunlink_vehicle(client, uavUid);
    try
        yunlink_takeoff(uav, 1.0, 0.001);
    catch exception
        fprintf('timeout or rejected: %s\n', exception.message);
    end
catch exception
    fprintf('connection error: %s\n', exception.message);
end

function vehicle = yunlink_vehicle(client, uid)
%YUNLINK_VEHICLE Select a Sunray UAV.
if nargin < 2
    vehicle = client.vehicle();
else
    vehicle = client.vehicle(py.str(char(uid)));
end
end

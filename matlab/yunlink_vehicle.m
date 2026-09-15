function vehicle = yunlink_vehicle(client, uid)
%YUNLINK_VEHICLE 按 entity_uid 选择并 attach 一架 UAV。
%   多机时必须传入完整 entity_uid，例如 "e-89c423-2-1"。
%   不要只用显示名 uav1。这一步才会订阅遥测；起飞等动作要另调控制函数。
if nargin < 2
    vehicle = client.vehicle();
else
    vehicle = client.vehicle(py.str(char(uid)));
end
end

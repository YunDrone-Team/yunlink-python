function ugv = yunlink_ugv(client, uid)
%YUNLINK_UGV 按 entity_uid 选择并 attach 一台无人车。
%   与 yunlink_vehicle 对称：先 connect，再 attach。不会发送运动指令。
if nargin < 2
    ugv = client.ugv();
else
    ugv = client.ugv(py.str(char(uid)));
end
end

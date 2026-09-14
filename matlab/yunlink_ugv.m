function ugv = yunlink_ugv(client, uid)
%YUNLINK_UGV Select and attach a Sunray UGV.
if nargin < 2
    ugv = client.ugv();
else
    ugv = client.ugv(py.str(char(uid)));
end
end

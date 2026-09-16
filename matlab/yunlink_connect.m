function client = yunlink_connect(address)
%YUNLINK_CONNECT 连接一台 YunLink Bridge。
%   client = yunlink_connect("192.168.10.10:9696")
%   只建立 Bridge Session，不会 attach 无人机或无人车，也不会申请控制权。
%   下一步用 yunlink_entities 看目录，再用 yunlink_vehicle / yunlink_ugv 选择设备。
yunlink_prepare_runtime();
sdk = py.importlib.import_module("yunlink_python");
try
    client = sdk.connect(py.str(char(address)));
catch exception
    error('yunlink:ConnectFailed', ...
        ['无法连接 %s\n%s\n', ...
         '请使用 ex01_discover 打印的「连接地址」，不要用文档里的示例 IP。'], ...
        string(address), exception.message);
end
end

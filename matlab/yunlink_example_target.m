function [address, uavUid, ugvUid, bridgeId] = yunlink_example_target()
%YUNLINK_EXAMPLE_TARGET 读取 Bridge/设备。
%   顺序：环境变量，再 yunlink.env，再 yunlink.env.example。
%   地址仍空则搜索局域网；只有一台 Bridge 才自动用它。

cfg = yunlink_load_example_env();
address = first_nonempty(getenv('YUNLINK_ADDRESS'), cfg.YUNLINK_ADDRESS);
uavUid = first_nonempty(getenv('YUNLINK_UAV'), cfg.YUNLINK_UAV);
ugvUid = first_nonempty(getenv('YUNLINK_UGV'), cfg.YUNLINK_UGV);
bridgeId = first_nonempty(getenv('YUNLINK_BRIDGE_ID'), cfg.YUNLINK_BRIDGE_ID);

if strlength(strtrim(address)) == 0
    fprintf(['未设置 YUNLINK_ADDRESS。\n', ...
        '搜索走 UDP 9697：广播 255.255.255.255、网卡广播、本网段 /24 单播。\n', ...
        'Windows 若弹出「Windows 安全警报」，请勾选专用网络并允许。\n']);
    timeoutS = 5;
    rawTimeout = first_nonempty(getenv('YUNLINK_DISCOVER_TIMEOUT'), cfg.YUNLINK_DISCOVER_TIMEOUT);
    if strlength(rawTimeout) > 0
        timeoutS = str2double(rawTimeout);
    end
    bridges = yunlink_discover(timeoutS);
    if isempty(bridges)
        error('yunlink:NoBridge', ...
            ['没有搜索到 Bridge。\n', ...
             '1) 确认仿真/飞机已开，Bridge 在听 9696/9697。\n', ...
             '2) Windows 防火墙允许 MATLAB 和 python.exe 的专用网络。\n', ...
             '3) 或把 ex01_discover 打印的「连接地址」写入 yunlink.env 的 YUNLINK_ADDRESS=。']);
    end
    if numel(bridges) > 1
        error('yunlink:MultipleBridges', ...
            ['搜索到 %d 个 Bridge。请把其中一台的连接地址写入 yunlink.env：\nYUNLINK_ADDRESS=%s'], ...
            numel(bridges), bridges(1).address);
    end
    address = string(bridges(1).address);
    fprintf('yunlink.env 未填地址，暂用搜到的唯一 Bridge %s\n', address);
    fprintf('建议写入 yunlink.env：YUNLINK_ADDRESS=%s\n', address);
end
end

function value = first_nonempty(first, second)
value = string(first);
if strlength(strtrim(value)) == 0
    value = string(second);
end
value = strtrim(value);
end

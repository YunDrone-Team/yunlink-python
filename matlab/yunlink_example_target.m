function [address, uavUid, ugvUid] = yunlink_example_target()
%YUNLINK_EXAMPLE_TARGET 解析示例用的 Bridge 地址和设备 ID。
%   优先环境变量 YUNLINK_ADDRESS / YUNLINK_UAV / YUNLINK_UGV。
%   地址未设置时，搜索局域网；只有一台 Bridge 就用它，避免连到文档里的示例 IP。
address = string(getenv('YUNLINK_ADDRESS'));
if strlength(strtrim(address)) == 0
    fprintf('未设置 YUNLINK_ADDRESS，正在搜索局域网 Bridge...\n');
    bridges = yunlink_discover(3);
    if isempty(bridges)
        error('yunlink:NoBridge', ...
            ['没有搜索到 Bridge。\n', ...
             '请确认飞机/仿真已启动，或在示例开头把 address 写成 ex01_discover 打印的连接地址。']);
    end
    if numel(bridges) > 1
        error('yunlink:MultipleBridges', ...
            ['搜索到 %d 个 Bridge，请设置 YUNLINK_ADDRESS 或把 address 写成其中一台的连接地址。\n', ...
             '例如：%s'], numel(bridges), bridges(1).address);
    end
    address = string(bridges(1).address);
    fprintf('使用搜索到的 Bridge %s\n', address);
end
uavUid = string(getenv('YUNLINK_UAV'));
ugvUid = string(getenv('YUNLINK_UGV'));
end

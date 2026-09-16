% 01_DISCOVER  搜索局域网里的 YunLink Bridge。
%
% 做什么：UDP 搜索。不连接、不 attach、不飞。
% 本步要抄：下面打印的「连接地址」和「entity_uid」。
% 填到哪：本目录 yunlink.env（先复制 yunlink.env.example）。
%   YUNLINK_ADDRESS=192.168.1.5:9696
%   YUNLINK_UAV=e-xxxxxxxx-2-1
%
% 搜索原理：向 UDP 9697 发查询。目标包括 255.255.255.255、网卡广播、
% 以及本网段每个 IP（有的 Wi-Fi 会丢掉有限广播）。Bridge 用 9697 回答。
% Windows 可能弹出「Windows 安全警报」：勾选专用网络并允许，否则会搜不到。
% 也可跳过搜索，直接在 yunlink.env 写死 YUNLINK_ADDRESS=ip:9696。

timeoutS = 5;

fprintf('正在搜索 Bridge，持续 %.0f 秒（UDP 9697）...\n', timeoutS);
fprintf('若 Windows 弹出防火墙，请允许专用网络。\n');
bridges = yunlink_discover(timeoutS);
if isempty(bridges)
    error('yunlink:NoBridge', ...
        ['没有搜索到 Bridge。\n', ...
         '请确认仿真/飞机已开；防火墙允许 MATLAB 和 python.exe；\n', ...
         '或把已知地址写入 yunlink.env 的 YUNLINK_ADDRESS=。']);
end
fprintf('搜索到 %d 个 Bridge。\n\n', numel(bridges));
for index = 1:numel(bridges)
    item = bridges(index);
    fprintf('Bridge [%d]\n', index);
    fprintf('  连接地址     %s    ← 写入 YUNLINK_ADDRESS=\n', item.address);
    fprintf('  Bridge ID    %s    ← 多台时写入 YUNLINK_BRIDGE_ID=\n', item.endpointUid);
    fprintf('  探测候选     %s\n', item.discoveryId);
    fprintf('  名称         %s\n', item.name);
    % 第一列才是后续脚本要的 entity_uid，不是 uav1 这种显示名。
    yunlink_print_catalog(item.entities);
end
fprintf('保存 yunlink.env 后再运行 ex02_connect_and_inspect（不要带 .m）。\n');

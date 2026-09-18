% 02_CONNECT_AND_INSPECT  连接 Bridge，只看设备目录。
%
% 做什么：TCP 连接 Session，打印目录。不 attach、不飞。
% 会不会飞：不会。
% 本步要读：yunlink.env 的 YUNLINK_ADDRESS（可留空则搜唯一 Bridge）。
% 本步要抄：下面表里的 entity_uid，写入 YUNLINK_UAV= / YUNLINK_UGV=。
% 上一步：ex01_discover。下一步：ex03_watch_state。

% 读 yunlink.env；地址空则再搜一次唯一 Bridge。
[address, ~, ~] = yunlink_example_target();

% 只建立 Bridge Session（TCP 9696），不会选中任何飞机，不申请控制权。
client = yunlink_connect(address);
% 脚本结束时关掉连接。
cleanup = onCleanup(@() yunlink_close(client));
fprintf('已连接 Bridge %s  %s\n', string(client.bridge_uid), string(client.bridge_address));

% 只读目录，不 attach。地面站已经连着这些设备时，这里仍能看到它们。
infos = yunlink_entities(client);
if isempty(infos)
    fprintf('Bridge 目录为空。确认仿真里 UAV/UGV 已起来。\n');
    return
end
fprintf('设备目录（%d）。第一列 entity_uid 才是后续脚本要填的 ID：\n', numel(infos));
% 表头：entity_uid / 名称 / 类型。后续脚本要的是第一列。
yunlink_print_catalog(infos);
fprintf('yunlink_connect 不会 attach。下一步 ex03_watch_state。\n');

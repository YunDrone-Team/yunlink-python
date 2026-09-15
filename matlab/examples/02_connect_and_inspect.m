% 02_CONNECT_AND_INSPECT  连接 Bridge 并打印设备目录。
% 本示例不 attach 设备，也不发送飞行指令。

address = "192.168.31.236:9696";

client = yunlink_connect(address);
cleanup = onCleanup(@() yunlink_close(client));
fprintf('已连接 Bridge %s  %s\n', string(client.bridge_uid), string(client.bridge_address));
infos = yunlink_entities(client);
if isempty(infos)
    fprintf('Bridge 目录为空。\n');
    return
end
fprintf('设备目录（%d）：\n', numel(infos));
for index = 1:numel(infos)
    item = infos(index);
    fprintf('  %s  %s  %s\n', item.uid, item.name, item.kind);
end
fprintf('\n请记下 entity_uid，供后续示例使用。yunlink_connect 不会 attach 设备。\n');

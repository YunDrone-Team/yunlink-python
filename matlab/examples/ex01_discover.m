% 01_DISCOVER  搜索局域网中的 YunLink Bridge。
% 本示例不连接、不 attach、不发送飞行指令。

timeoutS = 5;

fprintf('正在搜索 Bridge，持续 %.0f 秒...\n', timeoutS);
bridges = yunlink_discover(timeoutS);
if isempty(bridges)
    error('yunlink:NoBridge', '没有搜索到 Bridge。请确认 Bridge 已启动。');
end
fprintf('搜索到 %d 个 Bridge。\n\n', numel(bridges));
for index = 1:numel(bridges)
    item = bridges(index);
    fprintf('[%d] %s  %s  %s\n', index, item.discoveryId, item.endpointUid, item.name);
    fprintf('    连接地址: %s\n', item.address);
    for entityIndex = 1:numel(item.entities)
        entity = item.entities(entityIndex);
        fprintf('    %s  %s  %s\n', entity.uid, entity.name, entity.kind);
    end
end
fprintf('\n连接地址传给 yunlink_connect，entity_uid 传给 yunlink_vehicle。\n');

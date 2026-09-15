% 10_DISCOVER_SELECT_CONNECT  列出全部 Bridge，再按 Bridge ID 连接。
% 本示例不发送飞行指令。

bridgeId = string(getenv('YUNLINK_BRIDGE_ID'));
if strlength(bridgeId) == 0
    bridgeId = "89c423";
end
uavUid = string(getenv('YUNLINK_UAV'));
if strlength(uavUid) == 0
    uavUid = "e-89c423-2-1";
end
timeoutS = 5;

bridges = yunlink_discover(timeoutS);
if isempty(bridges)
    error('yunlink:NoBridge', '没有搜索到 Bridge。');
end
fprintf('搜索到 %d 个 Bridge：\n', numel(bridges));
for index = 1:numel(bridges)
    item = bridges(index);
    fprintf('  %s  %s\n', item.discoveryId, item.endpointUid);
end

match = bridges(strcmp({bridges.endpointUid}, char(bridgeId)));
if isempty(match)
    error('yunlink:BridgeNotFound', ...
        '搜索结果中没有 Bridge %s。请在本文件开头修改 bridgeId。', bridgeId);
end
if numel(match) > 1
    error('yunlink:MultipleBridges', '有多台 Bridge 匹配 %s。', bridgeId);
end

client = yunlink_connect(match.address);
cleanup = onCleanup(@() yunlink_close(client));
fprintf('已连接 %s  %s\n', match.endpointUid, match.address);
uav = yunlink_vehicle(client, uavUid);
disp(yunlink_state(uav).uavId);
disp(yunlink_state(uav).fresh);

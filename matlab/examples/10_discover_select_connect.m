% 10_DISCOVER_SELECT_CONNECT  列出全部 Bridge，再按 Bridge ID 连接。
% 本示例不发送飞行指令。

bridgeId = "f97f96";
uavUid = "e-f97f96-2-1";
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

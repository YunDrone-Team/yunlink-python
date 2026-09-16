% 08_DISCOVER_SELECT_CONNECT  多台 Bridge 时按 Bridge ID 选一台再连接。
%
% 做什么：搜索、挑选、连接、attach 一台 UAV。不飞。
% 本步要读：yunlink.env 的 YUNLINK_BRIDGE_ID、YUNLINK_UAV。
% Bridge ID 是 ex01 打印的「Bridge ID」列（短的那串，不是 ip:port）。
%
% 搜索用 UDP 9697。Windows 防火墙请允许专用网络。

[~, uavUid, ~, bridgeId] = yunlink_example_target();
timeoutS = 5;

fprintf('搜索 Bridge（UDP 9697）。若弹出防火墙，请允许专用网络。\n');
bridges = yunlink_discover(timeoutS);
if isempty(bridges)
    error('yunlink:NoBridge', '没有搜索到 Bridge。请看 ex01 的防火墙说明。');
end
fprintf('搜索到 %d 个 Bridge：\n', numel(bridges));
fprintf('%-22s  %s\n', '连接地址', 'Bridge ID (endpoint_uid)');
for index = 1:numel(bridges)
    item = bridges(index);
    fprintf('%-22s  %s\n', item.address, item.endpointUid);
end

if strlength(strtrim(bridgeId)) == 0
    if numel(bridges) ~= 1
        error('yunlink:MultipleBridges', ...
            '多台 Bridge。请把其中一台的 Bridge ID 写入 yunlink.env 的 YUNLINK_BRIDGE_ID=。');
    end
    match = bridges(1);
    fprintf('未填 YUNLINK_BRIDGE_ID，暂用唯一一台 %s\n', match.endpointUid);
else
    match = bridges(strcmp({bridges.endpointUid}, char(bridgeId)));
    if isempty(match)
        error('yunlink:BridgeNotFound', ...
            '没有 Bridge %s。YUNLINK_BRIDGE_ID 应填 endpoint_uid，不是 IP。', bridgeId);
    end
    if numel(match) > 1
        error('yunlink:MultipleBridges', '有多台 Bridge 匹配 %s。', bridgeId);
    end
end

client = yunlink_connect(match.address);
cleanup = onCleanup(@() yunlink_close(client));
fprintf('已连接 %s  %s\n', match.endpointUid, match.address);
uavUid = yunlink_example_pick(client, "sunray.uav", uavUid);
uav = yunlink_vehicle(client, uavUid);
fprintf('UAV entity_uid=%s fresh=%d\n', yunlink_state(uav).uavId, yunlink_state(uav).fresh);

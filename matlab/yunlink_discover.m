function bridges = yunlink_discover(timeout)
%YUNLINK_DISCOVER 搜索局域网 Bridge。
%   不连接、不 attach、不控制。timeout 默认 5 秒。返回 discoveryId=endpoint_uid@ip:port。
if nargin < 1
    timeout = 5;
end
yunlink_prepare_runtime();
sdk = py.importlib.import_module("yunlink_python");
raw = sdk.discover(pyargs('timeout', double(timeout)));
count = double(py.len(raw));
if count == 0
    bridges = struct('endpointUid', {}, 'ip', {}, 'tcpPort', {}, ...
        'address', {}, 'discoveryId', {}, 'name', {}, 'entities', {});
    return
end
bridges = repmat(empty_bridge(), 1, count);
for index = 1:count
    item = raw{index};
    bridges(index) = convert_bridge(item);
end
end

function bridge = empty_bridge()
bridge = struct( ...
    'endpointUid', "", ...
    'ip', "", ...
    'tcpPort', 0, ...
    'address', "", ...
    'discoveryId', "", ...
    'name', "", ...
    'entities', struct('uid', {}, 'name', {}, 'kind', {}));
end

function bridge = convert_bridge(item)
ip = char(string(item.ip));
port = double(item.tcp_port);
uid = char(string(item.endpoint_uid));
bridge = struct();
bridge.endpointUid = uid;
bridge.ip = ip;
bridge.tcpPort = port;
bridge.address = sprintf('%s:%d', ip, port);
bridge.discoveryId = sprintf('%s@%s:%d', uid, ip, port);
bridge.name = char(string(item.display_name));
bridge.entities = convert_entities(item.entities);
end

function entities = convert_entities(raw)
count = double(py.len(raw));
if count == 0
    entities = struct('uid', {}, 'name', {}, 'kind', {});
    return
end
entities = repmat(struct('uid', "", 'name', "", 'kind', ""), 1, count);
for index = 1:count
    item = raw{index};
    entities(index).uid = char(string(item.entity_uid));
    try
        entities(index).name = char(string(item.display_name));
    catch
        entities(index).name = entities(index).uid;
    end
    entities(index).kind = char(string(item.kind));
end
end

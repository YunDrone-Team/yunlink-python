% 01_DISCOVER  Search the LAN for YunLink Bridges.
% This example does not connect, attach, or send flight commands.

timeoutS = 5;

fprintf('Searching for Bridges for %.0f seconds...\n', timeoutS);
bridges = yunlink_discover(timeoutS);
if isempty(bridges)
    error('yunlink:NoBridge', 'No Bridge was discovered. Check that the Bridge is running.');
end
fprintf('Found %d Bridge(s).\n\n', numel(bridges));
for index = 1:numel(bridges)
    item = bridges(index);
    fprintf('[%d] %s  %s  %s\n', index, item.discoveryId, item.endpointUid, item.name);
    fprintf('    connect address: %s\n', item.address);
    for entityIndex = 1:numel(item.entities)
        entity = item.entities(entityIndex);
        fprintf('    %s  %s  %s\n', entity.uid, entity.name, entity.kind);
    end
end
fprintf('\nUse the connect address with yunlink_connect, and entity_uid with yunlink_vehicle.\n');

% 10_DISCOVER_SELECT_CONNECT  List every Bridge, then connect by Bridge ID.
% This example does not send flight commands.

bridgeId = "f97f96";
uavUid = "e-f97f96-2-1";
timeoutS = 5;

bridges = yunlink_discover(timeoutS);
if isempty(bridges)
    error('yunlink:NoBridge', 'No Bridge was discovered.');
end
fprintf('Discovered %d Bridge(s):\n', numel(bridges));
for index = 1:numel(bridges)
    item = bridges(index);
    fprintf('  %s  %s\n', item.discoveryId, item.endpointUid);
end

match = bridges(strcmp({bridges.endpointUid}, char(bridgeId)));
if isempty(match)
    error('yunlink:BridgeNotFound', ...
        'Bridge %s was not in the discovery list. Set bridgeId at the top of this file.', bridgeId);
end
if numel(match) > 1
    error('yunlink:MultipleBridges', 'Multiple Bridges matched %s.', bridgeId);
end

client = yunlink_connect(match.address);
cleanup = onCleanup(@() yunlink_close(client));
fprintf('Connected %s at %s\n', match.endpointUid, match.address);
uav = yunlink_vehicle(client, uavUid);
disp(yunlink_state(uav).uavId);
disp(yunlink_state(uav).fresh);

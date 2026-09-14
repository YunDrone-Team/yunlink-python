% 02_CONNECT_AND_INSPECT  Connect to a Bridge and print the device directory.
% This example does not attach a vehicle or send flight commands.

address = "192.168.31.236:9696";

client = yunlink_connect(address);
cleanup = onCleanup(@() yunlink_close(client));
fprintf('Connected to Bridge %s at %s\n', string(client.bridge_uid), string(client.bridge_address));
infos = yunlink_entities(client);
if isempty(infos)
    fprintf('The Bridge directory is empty.\n');
    return
end
fprintf('Directory (%d):\n', numel(infos));
for index = 1:numel(infos)
    item = infos(index);
    fprintf('  %s  %s  %s\n', item.uid, item.name, item.kind);
end
fprintf('\nRecord entity_uid for the next examples. connect() does not attach a device.\n');

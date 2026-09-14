function infos = yunlink_entities(client)
%YUNLINK_ENTITIES Read the Bridge directory. This does not attach a device.
raw = client.entities();
count = double(py.len(raw));
if count == 0
    infos = struct('uid', {}, 'name', {}, 'kind', {});
    return
end
infos = repmat(struct('uid', "", 'name', "", 'kind', ""), 1, count);
for index = 1:count
    item = raw{index};
    infos(index).uid = char(string(item.uid));
    infos(index).name = char(string(item.name));
    infos(index).kind = char(string(item.kind));
end
end

function infos = yunlink_entities(client)
%YUNLINK_ENTITIES 读取 Bridge 实时目录。
%   返回结构体数组，字段 uid/name/kind。不 attach 设备，也不申请权限。
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

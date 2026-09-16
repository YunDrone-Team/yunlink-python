function uid = yunlink_example_pick(client, kind, given)
%YUNLINK_EXAMPLE_PICK 选择目录中的一台设备。
%   given 非空则使用（应来自 yunlink.env 的 entity_uid）。
%   为空且该类型只有一台时暂用它，并提醒写入 yunlink.env。
%   多台则报错，必须填写 YUNLINK_UAV 或 YUNLINK_UGV。
if nargin >= 3 && strlength(strtrim(string(given))) > 0
    uid = string(given);
    fprintf('使用 yunlink.env / 环境变量中的 entity_uid：%s\n', uid);
    return
end
infos = yunlink_entities(client);
hits = strings(0, 1);
for index = 1:numel(infos)
    if string(infos(index).kind) == string(kind)
        hits(end + 1, 1) = string(infos(index).uid); %#ok<AGROW>
    end
end
if isempty(hits)
    error('yunlink:NoDevice', '目录里没有 %s。先跑 ex02_connect_and_inspect 看表。', kind);
end
if numel(hits) > 1
    error('yunlink:MultipleDevices', ...
        ['目录里有多台 %s，不能猜。\n', ...
         '打开 examples/yunlink.env，把 ex01/ex02 表中「entity_uid」那一列写入：\n', ...
         '  无人机 YUNLINK_UAV=\n  无人车 YUNLINK_UGV=\n第一台是 %s'], kind, hits(1));
end
uid = hits(1);
key = "YUNLINK_UAV";
if string(kind) == "sunray.ugv"
    key = "YUNLINK_UGV";
end
fprintf(['yunlink.env 未填 %s，目录里只有一台，暂用 entity_uid=%s\n', ...
    '请写入 examples/yunlink.env，避免以后连错机：\n%s=%s\n'], ...
    key, uid, key, uid);
end

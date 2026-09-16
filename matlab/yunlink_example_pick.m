function uid = yunlink_example_pick(client, kind, given)
%YUNLINK_EXAMPLE_PICK 选择目录中的一台设备。
%   若 given 非空则直接用；否则该 kind 必须恰好一台。
if nargin >= 3 && strlength(strtrim(string(given))) > 0
    uid = string(given);
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
    error('yunlink:NoDevice', '目录里没有 %s。', kind);
end
if numel(hits) > 1
    error('yunlink:MultipleDevices', ...
        '目录里有多台 %s，请设置 YUNLINK_UAV / YUNLINK_UGV。第一台是 %s。', kind, hits(1));
end
uid = hits(1);
fprintf('使用设备 %s (%s)\n', uid, kind);
end

function yunlink_print_catalog(infos)
%YUNLINK_PRINT_CATALOG 打印设备目录，第一列是 entity_uid。
if nargin < 1 || isempty(infos)
    fprintf('目录为空。\n');
    return
end
fprintf('%-22s  %-10s  %s\n', 'entity_uid', '名称', '类型');
fprintf('%-22s  %-10s  %s\n', '----------', '----', '----');
for index = 1:numel(infos)
    item = infos(index);
    fprintf('%-22s  %-10s  %s\n', item.uid, item.name, item.kind);
end
fprintf(['\n请把「entity_uid」那一列（例如 e-52c218-2-1）写入 examples/yunlink.env：\n', ...
    '  无人机 → YUNLINK_UAV=\n  无人车 → YUNLINK_UGV=\n不要填显示名 uav1 / ugv1。\n']);
end

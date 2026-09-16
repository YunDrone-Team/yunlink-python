function results = yunlink_live_check()
%YUNLINK_LIVE_CHECK 对着现场 Bridge 跑一遍示例会用到的路径。
%   先搜索、再连接。每一项打印 PASS / FAIL / SKIP。
%   有 UAV 就会起飞、短航线、降落；有 UGV 就点位 + Hold。不限仿真。
%   桌面会先确认一次，默认「继续飞」。

yunlink_prepare_runtime();
results = struct('name', {}, 'status', {}, 'detail', {});

fprintf(['\nYunLink 现场检查\n', ...
    '搜索 UDP 9697，连接 TCP 9696。Windows 若弹防火墙请允许专用网络。\n', ...
    '后面会起飞、短航线、降落（有 UAV）以及无人车点位（有 UGV）。不限仿真。\n\n']);

cfgTimeout = 5;
try
    cfg = yunlink_load_example_env();
    rawTimeout = first_nonempty(getenv('YUNLINK_DISCOVER_TIMEOUT'), cfg.YUNLINK_DISCOVER_TIMEOUT);
    if strlength(rawTimeout) > 0 && ~isnan(str2double(rawTimeout))
        cfgTimeout = str2double(rawTimeout);
    end
    results = add(results, 'load_env', 'PASS', '已读配置文件或将用搜索');
catch exception
    results = add(results, 'load_env', 'FAIL', exception.message);
    print_summary(results);
    return
end

fprintf('1) 搜索 Bridge，约 %.0f 秒...\n', cfgTimeout);
try
    bridges = yunlink_discover(cfgTimeout);
    if isempty(bridges)
        results = add(results, 'discover', 'FAIL', '没有搜到 Bridge');
        print_summary(results);
        return
    end
    results = add(results, 'discover', 'PASS', sprintf('%d 台', numel(bridges)));
    for index = 1:numel(bridges)
        fprintf('   [%d] 连接地址=%s  Bridge ID=%s\n', ...
            index, bridges(index).address, bridges(index).endpointUid);
    end
catch exception
    results = add(results, 'discover', 'FAIL', exception.message);
    print_summary(results);
    return
end

[address, uavUid, ugvUid] = yunlink_example_target();
fprintf('\n2) 连接 %s ...\n', address);
try
    client = yunlink_connect(address);
    cleanup = onCleanup(@() safe_close(client));
    results = add(results, 'connect', 'PASS', sprintf('%s %s', ...
        string(client.bridge_uid), string(client.bridge_address)));
catch exception
    results = add(results, 'connect', 'FAIL', exception.message);
    print_summary(results);
    return
end

fprintf('\n3) 设备目录\n');
try
    infos = yunlink_entities(client);
    yunlink_print_catalog(infos);
    if isempty(infos)
        results = add(results, 'catalog', 'FAIL', '目录为空');
    else
        results = add(results, 'catalog', 'PASS', sprintf('%d 台', numel(infos)));
    end
catch exception
    results = add(results, 'catalog', 'FAIL', exception.message);
    print_summary(results);
    return
end

uavs = filter_kind(infos, 'sunray.uav');
ugvs = filter_kind(infos, 'sunray.ugv');

fprintf('\n4) 故意 attach 一个不存在的设备（应对应 ex08）\n');
try
    yunlink_vehicle(client, 'does-not-exist');
    results = add(results, 'missing_entity', 'FAIL', '应当报错却成功了');
catch exception
    results = add(results, 'missing_entity', 'PASS', first_line(exception.message));
end

if isempty(uavs)
    results = add(results, 'uav_attach', 'SKIP', '目录没有 UAV');
    results = add(results, 'uav_state', 'SKIP', '目录没有 UAV');
else
    if strlength(strtrim(string(uavUid))) == 0
        uavUid = string(uavs(1).uid);
        fprintf('未填 YUNLINK_UAV，暂用 %s\n', uavUid);
    end
    fprintf('\n5) attach UAV %s\n', uavUid);
    try
        uav = yunlink_vehicle(client, uavUid);
        pause(0.5);
        results = add(results, 'uav_attach', 'PASS', uavUid);
        state = yunlink_state(uav);
        detail = sprintf('fresh=%d landed=%d z=%.3f', state.fresh, state.landed, state.position.z);
        if state.fresh
            results = add(results, 'uav_state', 'PASS', detail);
        else
            results = add(results, 'uav_state', 'FAIL', ['遥测不新鲜  ' detail]);
        end
    catch exception
        results = add(results, 'uav_attach', 'FAIL', exception.message);
        results = add(results, 'uav_state', 'SKIP', 'attach 失败');
        uav = [];
    end
end

if isempty(ugvs)
    results = add(results, 'ugv_attach', 'SKIP', '目录没有 UGV');
    results = add(results, 'ugv_state', 'SKIP', '目录没有 UGV');
    ugv = [];
else
    if strlength(strtrim(string(ugvUid))) == 0
        ugvUid = string(ugvs(1).uid);
        fprintf('未填 YUNLINK_UGV，暂用 %s\n', ugvUid);
    end
    fprintf('\n6) attach UGV %s\n', ugvUid);
    try
        ugv = yunlink_ugv(client, ugvUid);
        pause(0.5);
        results = add(results, 'ugv_attach', 'PASS', ugvUid);
        state = yunlink_ugv_state(ugv);
        detail = sprintf('fresh=%d', state.fresh);
        if state.fresh
            results = add(results, 'ugv_state', 'PASS', detail);
        else
            results = add(results, 'ugv_state', 'FAIL', ['遥测不新鲜  ' detail]);
        end
    catch exception
        results = add(results, 'ugv_attach', 'FAIL', exception.message);
        results = add(results, 'ugv_state', 'SKIP', 'attach 失败');
        ugv = [];
    end
end

fprintf('\n7) 建图 RPC 包装（仿真里 Livox 常不可用，失败记 SKIP）\n');
if exist('uav', 'var') && ~isempty(uav)
    try
        yunlink_mapping_start(uav);
        results = add(results, 'mapping_start', 'PASS', 'UAV MappingStart 已发出');
        try
            yunlink_mapping_stop(uav);
            results = add(results, 'mapping_stop', 'PASS', 'UAV MappingStop 已发出');
        catch exception
            results = add(results, 'mapping_stop', 'SKIP', first_line(exception.message));
        end
    catch exception
        results = add(results, 'mapping_start', 'SKIP', first_line(exception.message));
        results = add(results, 'mapping_stop', 'SKIP', 'start 未成功');
    end
else
    results = add(results, 'mapping_start', 'SKIP', '没有 UAV');
    results = add(results, 'mapping_stop', 'SKIP', '没有 UAV');
end

wantMotion = true;
if usejava('desktop')
    answer = questdlg( ...
        ['接下来会起飞、短平移、两点航线、悬停、降落。', newline, ...
         '有无人车则点位移动和 Hold。不限仿真。周围请空出。'], ...
        'YunLink 现场检查', '继续飞', '只读结束', '继续飞');
    wantMotion = strcmp(answer, '继续飞');
end

if ~wantMotion
    results = add(results, 'uav_takeoff', 'SKIP', '用户取消飞行');
    results = add(results, 'uav_translate', 'SKIP', '用户取消飞行');
    results = add(results, 'uav_waypoints', 'SKIP', '用户取消飞行');
    results = add(results, 'uav_hover', 'SKIP', '用户取消飞行');
    results = add(results, 'uav_land', 'SKIP', '用户取消飞行');
    results = add(results, 'ugv_move', 'SKIP', '用户取消运动');
    results = add(results, 'ugv_hold', 'SKIP', '用户取消运动');
    print_summary(results);
    return
end

height = 1.0;
fprintf('\n8) UAV 起飞 / 平移 / 航点 / 降落\n');
if exist('uav', 'var') && ~isempty(uav)
    try
        if yunlink_state(uav).landed
            yunlink_takeoff(uav, height, 30);
            results = add(results, 'uav_takeoff', 'PASS', sprintf('z=%.1f', height));
        else
            results = add(results, 'uav_takeoff', 'PASS', '已在空中，跳过起飞');
        end
    catch exception
        results = add(results, 'uav_takeoff', 'FAIL', first_line(exception.message));
    end
    try
        yunlink_translate(uav, "forward", 0.15, 0.6, 15);
        results = add(results, 'uav_translate', 'PASS', '前进 0.15m');
    catch exception
        results = add(results, 'uav_translate', 'FAIL', first_line(exception.message));
    end
    % 直控平移后 Planner 还不在 WAIT_MISSION，先悬停再交航点。
    try
        yunlink_hover(uav, 15);
        results = add(results, 'uav_hover_before_wp', 'PASS', '平移后悬停');
    catch exception
        results = add(results, 'uav_hover_before_wp', 'FAIL', first_line(exception.message));
    end
    try
        pos = yunlink_state(uav).position;
        points = [
            pos.x + 0.25, pos.y, height
            pos.x + 0.25, pos.y + 0.25, height
            ];
        yunlink_waypoints(uav, points, 120);
        results = add(results, 'uav_waypoints', 'PASS', '两点航线');
    catch exception
        results = add(results, 'uav_waypoints', 'FAIL', first_line(exception.message));
    end
    try
        yunlink_hover(uav, 15);
        results = add(results, 'uav_hover', 'PASS', '已悬停');
    catch exception
        results = add(results, 'uav_hover', 'FAIL', first_line(exception.message));
    end
    try
        if ~yunlink_state(uav).landed
            yunlink_land(uav, 30);
            results = add(results, 'uav_land', 'PASS', '已降落');
        else
            results = add(results, 'uav_land', 'PASS', '已在地上');
        end
    catch exception
        results = add(results, 'uav_land', 'FAIL', first_line(exception.message));
    end
else
    results = add(results, 'uav_takeoff', 'SKIP', '没有 UAV');
    results = add(results, 'uav_translate', 'SKIP', '没有 UAV');
    results = add(results, 'uav_waypoints', 'SKIP', '没有 UAV');
    results = add(results, 'uav_hover', 'SKIP', '没有 UAV');
    results = add(results, 'uav_land', 'SKIP', '没有 UAV');
end

fprintf('\n9) UGV 点位 / Hold\n');
if exist('ugv', 'var') && ~isempty(ugv)
    try
        start = yunlink_ugv_state(ugv).position;
        yunlink_ugv_move_to(ugv, start.x + 0.3, start.y, 45);
        results = add(results, 'ugv_move', 'PASS', '+0.3m');
    catch exception
        results = add(results, 'ugv_move', 'FAIL', first_line(exception.message));
    end
    try
        yunlink_ugv_hold(ugv, 15);
        results = add(results, 'ugv_hold', 'PASS', '已 Hold');
    catch exception
        results = add(results, 'ugv_hold', 'FAIL', first_line(exception.message));
    end
else
    results = add(results, 'ugv_move', 'SKIP', '没有 UGV');
    results = add(results, 'ugv_hold', 'SKIP', '没有 UGV');
end

print_summary(results);
end

function results = add(results, name, status, detail)
item.name = char(string(name));
item.status = char(string(status));
item.detail = char(first_line(detail));
results(end + 1) = item; %#ok<AGROW>
fprintf('   [%s] %s  %s\n', item.status, item.name, item.detail);
end

function print_summary(results)
fprintf('\n======== 现场检查汇总 ========\n');
passN = 0;
failN = 0;
skipN = 0;
for index = 1:numel(results)
    item = results(index);
    fprintf('%-6s  %-16s  %s\n', item.status, item.name, item.detail);
    switch item.status
        case 'PASS'
            passN = passN + 1;
        case 'FAIL'
            failN = failN + 1;
        otherwise
            skipN = skipN + 1;
    end
end
fprintf('通过 %d  失败 %d  跳过 %d\n', passN, failN, skipN);
if failN == 0
    fprintf('失败项为 0。搜索、连接、状态、起飞/航点/降落路径已覆盖对应 example。\n');
else
    fprintf('有失败项。先看 discover / connect / catalog，再往下查。\n');
end
end

function infos = filter_kind(infos, kind)
if isempty(infos)
    infos = [];
    return
end
keep = false(1, numel(infos));
for index = 1:numel(infos)
    keep(index) = strcmp(infos(index).kind, kind);
end
infos = infos(keep);
end

function text = first_line(value)
text = string(value);
text = replace(text, newline, ' ');
text = strtrim(text);
if strlength(text) > 180
    text = extractBefore(text, 181) + "...";
end
end

function value = first_nonempty(first, second)
value = string(first);
if strlength(strtrim(value)) == 0
    value = string(second);
end
value = strtrim(value);
end

function safe_close(client)
try
    yunlink_close(client);
catch
end
end

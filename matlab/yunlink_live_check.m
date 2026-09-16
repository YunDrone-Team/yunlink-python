function results = yunlink_live_check()
%YUNLINK_LIVE_CHECK 对着现场 Bridge 跑一遍示例会用到的路径。
%   先搜索、再连接。每一项打印 PASS / FAIL / SKIP。
%   默认不起飞、不跑航点。桌面会问要不要做短时控制。
%
%   若只想手跑几个 example，最小集是：
%     ex00_setup → ex01_discover → ex02_connect_and_inspect →
%     ex03_watch_state → ex08_errors
%   这几条过了，只读和报错路径就算通；ex04 起才是真飞。

yunlink_prepare_runtime();
results = struct('name', {}, 'status', {}, 'detail', {});

fprintf(['\nYunLink 现场检查\n', ...
    '搜索 UDP 9697，连接 TCP 9696。Windows 若弹防火墙请允许专用网络。\n', ...
    '最小手测集：ex00、ex01、ex02、ex03、ex08。本脚本覆盖这些路径。\n\n']);

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

wantMotion = false;
if usejava('desktop')
    answer = questdlg( ...
        ['默认到此结束（覆盖 ex01/ex02/ex03/ex08/ex11 只读路径）。', newline, ...
         '点「短时控制」才会：UAV 已在空中则 hover；UGV 则 Hold。', newline, ...
         '不会自动起飞，也不会跑航点。'], ...
        'YunLink 现场检查', '只读结束', '短时控制', '只读结束');
    wantMotion = strcmp(answer, '短时控制');
end

if ~wantMotion
    results = add(results, 'uav_hover', 'SKIP', '未勾选短时控制 / 非桌面');
    results = add(results, 'ugv_hold', 'SKIP', '未勾选短时控制 / 非桌面');
    results = add(results, 'uav_takeoff', 'SKIP', '本脚本不自动起飞');
    results = add(results, 'uav_waypoints', 'SKIP', '本脚本不跑航点');
    print_summary(results);
    return
end

fprintf('\n8) 短时控制（不起飞、不航点）\n');
if exist('uav', 'var') && ~isempty(uav)
    try
        state = yunlink_state(uav);
        if state.landed
            results = add(results, 'uav_hover', 'SKIP', '在地上，未起飞所以不 hover');
        else
            yunlink_hover(uav, 8);
            results = add(results, 'uav_hover', 'PASS', '已 hover');
        end
    catch exception
        results = add(results, 'uav_hover', 'FAIL', first_line(exception.message));
    end
else
    results = add(results, 'uav_hover', 'SKIP', '没有 UAV');
end
results = add(results, 'uav_takeoff', 'SKIP', '本脚本不自动起飞');
results = add(results, 'uav_waypoints', 'SKIP', '本脚本不跑航点');

if exist('ugv', 'var') && ~isempty(ugv)
    try
        yunlink_ugv_hold(ugv, 8);
        results = add(results, 'ugv_hold', 'PASS', '已 Hold');
    catch exception
        results = add(results, 'ugv_hold', 'FAIL', first_line(exception.message));
    end
else
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
    fprintf('失败项为 0。只读路径可视为已覆盖其余只读 example。\n');
    fprintf('起飞/航点请另外手跑 ex04 / ex05，本脚本故意不自动飞。\n');
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

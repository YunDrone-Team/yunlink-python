function exampleDir = yunlink_examples()
%YUNLINK_EXAMPLES 把 MATLAB 当前文件夹切到示例目录并打开文件浏览器。
%   这些脚本就是教程。先运行 ex00_setup，再按编号一直做到 ex12_live_check。

root = fileparts(mfilename('fullpath'));
exampleDir = fullfile(root, 'examples');
if ~isfolder(exampleDir)
    error('yunlink:ExamplesMissing', ...
        'MATLAB example folder was not found next to the Toolbox: %s', exampleDir);
end

cd(exampleDir);
if usejava('desktop')
    filebrowser;
    commandwindow;
end

files = dir(fullfile(exampleDir, '*.m'));
fprintf('\n示例目录（这些脚本就是教程，打开看注释，按编号跑）：\n  %s\n\n', exampleDir);
fprintf('先运行 ex00_setup.m，再按 01、02、…、12 往下做。不要改脚本中间的变量。\n');
fprintf('配置写在 yunlink.env；没有就直接改 yunlink.env.example。填连接地址和 entity_uid（不是 uav1）。\n');
fprintf('Windows 搜索若弹出防火墙，请允许专用网络。UDP 9697，TCP 9696。\n\n');
fprintf('  %-36s  %-8s  %s\n', '脚本', '会发控制', '学什么');
ordered = { ...
    'ex00_setup.m', 'ex01_discover.m', 'ex02_connect_and_inspect.m', ...
    'ex03_watch_state.m', 'ex04_flight_basics.m', 'ex05_cancel_action.m', ...
    'ex06_ugv_control.m', 'ex07_errors.m', 'ex08_discover_select_connect.m', ...
    'ex09_multi_device_control.m', 'ex10_multi_device_state.m', ...
    'ex11_observe_live.m', 'ex12_live_check.m'};
printed = false(1, numel(files));
for index = 1:numel(ordered)
    [motion, blurb] = example_blurb(ordered{index});
    fprintf('  %-36s  %-8s  %s\n', ordered{index}, motion, blurb);
    for fileIndex = 1:numel(files)
        if strcmp(files(fileIndex).name, ordered{index})
            printed(fileIndex) = true;
        end
    end
end
for index = 1:numel(files)
    if printed(index)
        continue
    end
    [motion, blurb] = example_blurb(files(index).name);
    fprintf('  %-36s  %-8s  %s\n', files(index).name, motion, blurb);
end
fprintf('\n完整表格见本目录 README.md。以后运行 yunlink_examples 会回到这里。\n');

if usejava('desktop') && exist(fullfile(exampleDir, 'ex00_setup.m'), 'file')
    edit('ex00_setup.m');
end
end

function [motion, text] = example_blurb(name)
switch name
    case 'ex00_setup.m'
        motion = '否';
        text = '配置 Python 和通信库';
    case 'ex01_discover.m'
        motion = '否';
        text = '搜索 Bridge，抄连接地址和 entity_uid';
    case 'ex02_connect_and_inspect.m'
        motion = '否';
        text = '连接 Bridge 并打印目录';
    case 'ex03_watch_state.m'
        motion = '否';
        text = '读取 UAV 状态，不飞';
    case 'ex04_flight_basics.m'
        motion = '会飞';
        text = '起飞约 1 m、短移、悬停、降落';
    case 'ex05_cancel_action.m'
        motion = '会飞';
        text = '启动移动后取消';
    case 'ex06_ugv_control.m'
        motion = '会走';
        text = '无人车点位、速度、Hold';
    case 'ex07_errors.m'
        motion = '可能飞';
        text = '连接和动作异常处理';
    case 'ex08_discover_select_connect.m'
        motion = '否';
        text = '按 Bridge ID 选择连接';
    case 'ex09_multi_device_control.m'
        motion = '否';
        text = '多设备状态，不飞';
    case 'ex10_multi_device_state.m'
        motion = '否';
        text = '连续打印多设备状态';
    case 'ex11_observe_live.m'
        motion = '否';
        text = '命令窗口刷新遥测';
    case 'ex12_live_check.m'
        motion = '会飞';
        text = '现场全量检查，会起飞降落';
    case 'read_state_demo.m'
        motion = '否';
        text = '只读状态（ex03 短版）';
    case 'basic_flight_demo.m'
        motion = '会飞';
        text = '会起飞、移动、降落（ex04 短版）';
    otherwise
        motion = '';
        text = '示例脚本';
end
end

function exampleDir = yunlink_examples()
%YUNLINK_EXAMPLES 把 MATLAB 当前文件夹切到示例目录并打开文件浏览器。
%   先运行 ex00_setup，再按 ex01_discover 往下做。

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
fprintf('\n示例目录：\n  %s\n\n', exampleDir);
fprintf('在左侧 Current Folder 里打开脚本。先运行 ex00_setup.m，再按编号往下做。\n');
fprintf('配置写在 yunlink.env；没有就直接改 yunlink.env.example。填连接地址和 entity_uid（不是 uav1）。\n');
fprintf('Windows 搜索若弹出防火墙，请允许专用网络。UDP 9697，TCP 9696。\n\n');
for index = 1:numel(files)
    fprintf('  %-32s  %s\n', files(index).name, example_blurb(files(index).name));
end
fprintf('\n说明见本目录 README.md。以后运行 yunlink_examples 会回到这里。\n');

if usejava('desktop') && exist(fullfile(exampleDir, 'ex00_setup.m'), 'file')
    edit('ex00_setup.m');
end
end

function text = example_blurb(name)
switch name
    case 'ex00_setup.m'
        text = '配置 Python 和通信库';
    case 'ex01_discover.m'
        text = '搜索 Bridge，不连接';
    case 'ex02_connect_and_inspect.m'
        text = '连接 Bridge 并打印目录';
    case 'ex03_watch_state.m'
        text = '读取 UAV 状态，不飞';
    case 'ex04_flight_basics.m'
        text = '起飞、平移、悬停、降落';
    case 'ex05_waypoints.m'
        text = '多航点 Planner 任务';
    case 'ex06_cancel_action.m'
        text = '启动移动后取消';
    case 'ex07_ugv_control.m'
        text = '无人车点位、速度、Hold';
    case 'ex08_errors.m'
        text = '连接和动作异常处理';
    case 'ex10_discover_select_connect.m'
        text = '按 Bridge ID 选择连接';
    case 'ex11_multi_device_control.m'
        text = '多设备状态，不飞';
    case 'ex12_multi_uav_waypoints.m'
        text = '多机短航线，会飞';
    case 'ex13_multi_device_state.m'
        text = '连续打印多设备状态';
    case 'ex14_observe_live.m'
        text = '命令窗口刷新遥测';
    case 'read_state_demo.m'
        text = '只读状态，不会起飞';
    case 'basic_flight_demo.m'
        text = '会起飞、移动、降落';
    case 'ex99_live_check.m'
        text = '现场全量检查，默认不飞';
    otherwise
        text = '示例脚本';
end
end

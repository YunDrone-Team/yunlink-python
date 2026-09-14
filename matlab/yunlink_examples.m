function exampleDir = yunlink_examples()
%YUNLINK_EXAMPLES Open the MATLAB example folder in Current Folder.
%   yunlink_examples changes MATLAB's current folder to the bundled
%   examples, shows the file browser, and opens the read-only demo.

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
fprintf('在左侧 Current Folder 里双击文件，或在命令窗口输入文件名运行。\n');
fprintf('先改地址和 entity_uid，再运行。\n\n');
for index = 1:numel(files)
    fprintf('  %-24s  %s\n', files(index).name, example_blurb(files(index).name));
end
fprintf('\n以后随时运行 yunlink_examples 都会回到这里。\n');

if usejava('desktop') && exist(fullfile(exampleDir, '00_setup.m'), 'file')
    edit('00_setup.m');
elseif usejava('desktop') && exist(fullfile(exampleDir, 'read_state_demo.m'), 'file')
    edit('read_state_demo.m');
end
end

function text = example_blurb(name)
switch name
    case '00_setup.m'
        text = '填 Python 和 bundle 路径后点 Run';
    case 'read_state_demo.m'
        text = '只读状态，不会起飞';
    case 'basic_flight_demo.m'
        text = '会起飞、移动、降落';
    otherwise
        text = '示例脚本';
end
end

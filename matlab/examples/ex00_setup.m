% 00_SETUP  第一次必跑：给 MATLAB 配上 Python 3.10–3.13 和 zip 里的通信库。
%
% 做什么：安装 yunlink / yunlink_python wheel。不连飞机，不飞。
% 会不会飞：不会。这是教程的第 0 步。
% 本步要填：下面的 pythonExe、bundleDir（可留空自动找）。
% 下一步：复制 yunlink.env.example 为 yunlink.env，再跑 ex01_discover。
% 这些 example 就是教程：打开脚本看注释，按编号学，不要先抄 README 里的函数。
%
% Windows 第一次搜机或第一次调 Python 时，可能弹出「Windows 安全警报」。
% 请勾选「专用网络」并允许访问。搜索用 UDP 9697，连接用 TCP 9696。

% pythonExe：Python 可执行文件，不要用 MATLAB 自带 3.14。
%   Windows:  "C:\Users\<用户>\AppData\Local\Programs\Python\Python313\python.exe"
%   macOS:    "/opt/homebrew/bin/python3.13"
%   Linux:    "/usr/bin/python3.12"
pythonExe = "";

% bundleDir：解压后的 zip 目录。里面应有 .mltbx 和 wheels 文件夹。
% 若 Windows 解压多了一层，指到内层那一层也可以；setup 会自动解开。
bundleDir = "";

thisDir = fileparts(mfilename('fullpath'));
% 工具箱函数在 examples 的上一级。
addpath(fileparts(thisDir));

% 留空则按常见安装路径猜测 Python。
if strlength(strtrim(string(pythonExe))) == 0
    pythonExe = local_find_python();
end
% 留空则在下载目录里找解压后的 bundle。
if strlength(strtrim(string(bundleDir))) == 0
    bundleDir = local_find_bundle();
end
if ~isfile(char(pythonExe))
    error('yunlink:MissingPython', ...
        ['未找到 Python 可执行文件。\n', ...
         '请在本文件开头把 pythonExe 设为 Python 3.10、3.11、3.12 或 3.13。']);
end
if ~isfolder(bundleDir)
    error('yunlink:MissingBundle', ...
        ['未找到发布包目录。\n', ...
         '请把 bundleDir 设为解压后的 zip 目录（含 .mltbx 和 wheels）。']);
end

fprintf('Python: %s\nBundle: %s\n', pythonExe, bundleDir);
% 解压 wheel 到该 Python，并记住路径。不走 pip。
yunlink_setup(pythonExe, bundleDir);

cd(thisDir);
fprintf(['\n配置完成。\n', ...
    '1) 把连接地址和 entity_uid 写入本目录 yunlink.env；没有这份文件就直接改 yunlink.env.example。\n', ...
    '2) 运行 ex01_discover（不要带 .m）。\n', ...
    'Windows 若弹出防火墙，请允许专用网络。\n']);
if usejava('desktop')
    filebrowser;
    commandwindow;
end

function pythonExe = local_find_python()
homeDir = getenv('USERPROFILE');
if strlength(string(homeDir)) == 0
    homeDir = getenv('HOME');
end
localApp = getenv('LOCALAPPDATA');
candidates = {
    fullfile(localApp, 'Programs', 'Python', 'Python313', 'python.exe')
    fullfile(localApp, 'Programs', 'Python', 'Python312', 'python.exe')
    fullfile(localApp, 'Programs', 'Python', 'Python311', 'python.exe')
    fullfile(localApp, 'Programs', 'Python', 'Python310', 'python.exe')
    fullfile(homeDir, 'miniconda3', 'python.exe')
    fullfile(homeDir, 'Miniconda3', 'python.exe')
    fullfile(homeDir, 'anaconda3', 'python.exe')
    fullfile(homeDir, 'AppData', 'Local', 'Programs', 'Python', 'Python313', 'python.exe')
    '/opt/homebrew/bin/python3.13'
    '/opt/homebrew/bin/python3.12'
    '/opt/homebrew/bin/python3.11'
    '/opt/homebrew/bin/python3.10'
    '/usr/local/bin/python3.13'
    '/usr/local/bin/python3.12'
    '/usr/bin/python3.13'
    '/usr/bin/python3.12'
    '/usr/bin/python3.11'
    '/usr/bin/python3.10'
    };
pythonExe = "";
for index = 1:numel(candidates)
    item = candidates{index};
    if strlength(string(item)) > 0 && isfile(item)
        pythonExe = item;
        return
    end
end
error('yunlink:MissingPython', ...
    ['未找到 Python 3.10–3.13。\n', ...
     '请在 ex00_setup.m 开头填写 pythonExe。']);
end

function bundleDir = local_find_bundle()
roots = {};
homeDir = getenv('USERPROFILE');
if strlength(string(homeDir)) == 0
    homeDir = getenv('HOME');
end
if strlength(string(homeDir)) > 0
    roots = {fullfile(homeDir, 'Downloads'), fullfile(homeDir, 'Downloads', 'Edge')};
end
newest = datetime(0, 1, 1);
bundleDir = "";
for rootIndex = 1:numel(roots)
    if ~isfolder(roots{rootIndex})
        continue
    end
    hits = dir(fullfile(roots{rootIndex}, 'yunlink-sunray-matlab-*-bundle'));
    for index = 1:numel(hits)
        if ~hits(index).isdir
            continue
        end
        candidate = fullfile(hits(index).folder, hits(index).name);
        stamp = datetime(hits(index).datenum, 'ConvertFrom', 'datenum');
        mltbx = dir(fullfile(candidate, 'yunlink-sunray-matlab-*.mltbx'));
        if isempty(mltbx)
            nested = dir(fullfile(candidate, 'yunlink-sunray-matlab-*-bundle'));
            if ~isempty(nested) && nested(1).isdir
                candidate = fullfile(nested(1).folder, nested(1).name);
                mltbx = dir(fullfile(candidate, 'yunlink-sunray-matlab-*.mltbx'));
            end
        end
        if ~isempty(mltbx) && stamp >= newest
            newest = stamp;
            bundleDir = candidate;
        end
    end
end
if strlength(bundleDir) == 0
    error('yunlink:MissingBundle', ...
        '未找到解压后的发布包目录。请在 ex00_setup.m 开头填写 bundleDir。');
end
end

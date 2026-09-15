% 00_SETUP  填写 pythonExe 和 bundleDir，然后点击 Run。
% 下一步运行本目录的 ex01_discover.m。

% pythonExe：Python 3.10–3.13 的可执行文件，不要用 MATLAB 自带的 3.14。
%   Windows:  "C:\Users\<用户>\AppData\Local\Programs\Python\Python313\python.exe"
%   macOS:    "/opt/homebrew/bin/python3.13"  或  "/usr/local/bin/python3.13"
%   Linux:    "/usr/bin/python3.12"
pythonExe = "";

% bundleDir：解压后的 yunlink-sunray-matlab-1.1.0-bundle 目录。
% 留空则在用户下载目录中查找。
bundleDir = "";

thisDir = fileparts(mfilename('fullpath'));
addpath(fileparts(thisDir));
if strlength(strtrim(string(pythonExe))) == 0
    pythonExe = local_find_python();
end
if strlength(strtrim(string(bundleDir))) == 0
    bundleDir = local_find_bundle();
end
if ~isfile(char(pythonExe))
    error('yunlink:MissingPython', ...
        ['未找到 Python 可执行文件。\n', ...
         '请在 ex00_setup.m 开头把 pythonExe 设为 Python 3.10、3.11、3.12 或 3.13。']);
end
if ~isfolder(bundleDir)
    error('yunlink:MissingBundle', ...
        ['未找到发布包目录。\n', ...
         '请在 ex00_setup.m 开头把 bundleDir 设为解压后的 zip 目录。']);
end

fprintf('Python: %s\nBundle: %s\n', pythonExe, bundleDir);
yunlink_setup(pythonExe, bundleDir);

cd(thisDir);
fprintf(['\n配置完成。接下来运行 ex01_discover，然后运行 ex02_connect_and_inspect。\n', ...
         '飞行示例从 ex04_flight_basics 开始。说明见本目录 README.md。\n']);
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
        if isfile(fullfile(candidate, 'yunlink-sunray-matlab-1.1.0.mltbx')) && stamp >= newest
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

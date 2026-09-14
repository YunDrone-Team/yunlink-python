% 00_SETUP  Fill pythonExe and bundleDir, then click Run.
% Next: edit read_state_demo.m in this folder.

% pythonExe: Python 3.10-3.13 executable, not MATLAB's Python 3.14.
%   Windows:  "C:\Users\<user>\AppData\Local\Programs\Python\Python313\python.exe"
%   macOS:    "/opt/homebrew/bin/python3.13"  or  "/usr/local/bin/python3.13"
%   Linux:    "/usr/bin/python3.12"
pythonExe = "";

% bundleDir: unzipped yunlink-sunray-matlab-1.1.0-bundle folder.
% Leave empty to search the user Downloads folder.
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
        ['Python executable not found.\n', ...
         'Set pythonExe at the top of 00_setup.m to Python 3.10, 3.11, 3.12, or 3.13.']);
end
if ~isfolder(bundleDir)
    error('yunlink:MissingBundle', ...
        ['Release bundle folder not found.\n', ...
         'Set bundleDir at the top of 00_setup.m to the unzipped zip.']);
end

fprintf('Python: %s\nBundle: %s\n', pythonExe, bundleDir);
yunlink_setup(pythonExe, bundleDir);

cd(thisDir);
if usejava('desktop')
    filebrowser;
    commandwindow;
    edit(fullfile(thisDir, '01_discover.m'));
end
fprintf(['\nSetup finished. Next run 01_discover.m, then 02_connect_and_inspect.m.\n', ...
         'Flight examples start at 04_flight_basics.m. See README.md in this folder.\n']);

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
    ['Could not find Python 3.10-3.13.\n', ...
     'Set pythonExe at the top of 00_setup.m to the interpreter executable.']);
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
        'Could not find the unzipped release folder. Set bundleDir at the top of 00_setup.m.');
end
end

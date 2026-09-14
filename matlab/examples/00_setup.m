% 00_SETUP  Fill the two paths, then click Run. No extra dialogs.
% After it finishes, this folder stays open. Edit read_state_demo.m next.

pythonExe = "/opt/homebrew/bin/python3.13";
bundleDir = "";

% pythonExe must be 3.10-3.13. Do not use python3 or MATLAB's 3.14.
% On this Mac the working interpreter is /opt/homebrew/bin/python3.13.
% bundleDir is the unzipped yunlink-sunray-matlab-1.1.0-bundle folder.
% Leave it empty to search ~/Downloads and ~/Downloads/Edge.

thisDir = fileparts(mfilename('fullpath'));
addpath(fileparts(thisDir));
if strlength(strtrim(string(bundleDir))) == 0
    bundleDir = local_find_bundle();
end
if ~isfile(pythonExe) && ~isfile(char(pythonExe))
    error('yunlink:MissingPython', ...
        ['Python executable not found:\n%s\n', ...
         'Set pythonExe at the top of 00_setup.m to Python 3.10-3.13.'], pythonExe);
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
    edit(fullfile(thisDir, 'read_state_demo.m'));
end
fprintf(['\n依赖已装好。请在 read_state_demo.m 里改 Bridge 地址和 entity_uid，然后 Run。\n', ...
         '只读用 read_state_demo.m；会飞的是 basic_flight_demo.m。\n']);

function bundleDir = local_find_bundle()
roots = {};
homeDir = getenv('HOME');
if strlength(string(homeDir)) == 0
    homeDir = getenv('USERPROFILE');
end
if strlength(string(homeDir)) > 0
    roots = {fullfile(homeDir, 'Downloads', 'Edge'), fullfile(homeDir, 'Downloads')};
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
        'Could not find yunlink-sunray-matlab-*-bundle under Downloads. Set bundleDir at the top of this file.');
end
end

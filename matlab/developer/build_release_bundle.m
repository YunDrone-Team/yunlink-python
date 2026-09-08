function bundleDir = build_release_bundle(bundleDir, bindingDir)
%BUILD_RELEASE_BUNDLE Assemble the user MATLAB install zip contents.
%   build_release_bundle(DIR, BINDING_DIR) builds the .mltbx, copies the
%   pure-Python SDK wheel, copies platform binding wheels from BINDING_DIR,
%   and writes a short INSTALL.txt. BINDING_DIR is optional.

repoRoot = fileparts(fileparts(fileparts(mfilename('fullpath'))));
if nargin < 1 || strlength(string(bundleDir)) == 0
    bundleDir = fullfile(repoRoot, 'dist', 'yunlink-sunray-matlab-1.1.0-bundle');
else
    bundleDir = char(string(bundleDir));
end
if nargin < 2
    bindingDir = '';
else
    bindingDir = char(string(bindingDir));
end

if ~isfolder(bundleDir)
    mkdir(bundleDir);
end

mltbx = fullfile(bundleDir, 'yunlink-sunray-matlab-1.1.0.mltbx');
sdkWheel = fullfile(repoRoot, 'dist', 'yunlink_python-1.1.0-py3-none-any.whl');
addpath(fullfile(repoRoot, 'matlab'));
build_toolbox(mltbx, sdkWheel);

if isfile(sdkWheel)
    copyfile(sdkWheel, fullfile(bundleDir, 'yunlink_python-1.1.0-py3-none-any.whl'));
end

if strlength(string(bindingDir)) > 0
    if ~isfolder(bindingDir)
        error('yunlink:InvalidBindingDir', 'Binding directory does not exist: %s', bindingDir);
    end
    wheels = dir(fullfile(bindingDir, 'yunlink-*.whl'));
    copied = 0;
    for index = 1:numel(wheels)
        if startsWith(wheels(index).name, 'yunlink_python-')
            continue;
        end
        copyfile(fullfile(wheels(index).folder, wheels(index).name), ...
            fullfile(bundleDir, wheels(index).name));
        copied = copied + 1;
    end
    if copied == 0
        warning('yunlink:NoBindingWheels', 'No YunLink binding wheels were copied from %s.', bindingDir);
    end
end

installFile = fullfile(bundleDir, 'INSTALL.txt');
fid = fopen(installFile, 'w');
if fid < 0
    error('yunlink:WriteFailed', 'Could not write %s', installFile);
end
cleaner = onCleanup(@() fclose(fid));
fprintf(fid, ['Install yunlink-sunray-matlab-1.1.0.mltbx from MATLAB:\n', ...
    'Home -> Add-Ons -> Install from File.\n\n', ...
    'Then run yunlink_setup in the MATLAB command window.\n', ...
    'Select Python 3.10/3.11/3.12 and the YunLink binding wheel for this computer.\n', ...
    'The wizard does not connect to a vehicle.\n']);
clear cleaner;

fprintf('Release bundle ready in %s\n', bundleDir);
end

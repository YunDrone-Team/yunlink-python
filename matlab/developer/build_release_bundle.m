function bundleDir = build_release_bundle(bundleDir, bindingDir)
%BUILD_RELEASE_BUNDLE Assemble the user MATLAB install directory.
repoRoot = fileparts(fileparts(fileparts(mfilename('fullpath'))));
matlabRoot = fullfile(repoRoot, 'matlab');
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

if isfolder(bundleDir)
    rmdir(bundleDir, 's');
end
mkdir(bundleDir);

mltbx = fullfile(bundleDir, 'yunlink-sunray-matlab-1.1.0.mltbx');
sdkWheel = fullfile(repoRoot, 'dist', 'yunlink_python-1.1.0-py3-none-any.whl');
addpath(matlabRoot);
build_toolbox(mltbx, sdkWheel);

if ~isfile(sdkWheel)
    error('yunlink:MissingSdkWheel', 'SDK wheel does not exist: %s', sdkWheel);
end
copyfile(sdkWheel, fullfile(bundleDir, 'yunlink_python-1.1.0-py3-none-any.whl'));
copyfile(fullfile(matlabRoot, 'INSTALL.txt'), fullfile(bundleDir, 'INSTALL.txt'));
copyfile(fullfile(matlabRoot, 'README.md'), fullfile(bundleDir, 'README.md'));

if strlength(string(bindingDir)) == 0
    error('yunlink:MissingBindingDir', 'A directory of YunLink binding wheels is required.');
end
if ~isfolder(bindingDir)
    error('yunlink:InvalidBindingDir', 'Binding directory does not exist: %s', bindingDir);
end

wheelDir = fullfile(bundleDir, 'wheels');
mkdir(wheelDir);
wheels = dir(fullfile(bindingDir, 'yunlink-*.whl'));
copied = 0;
for index = 1:numel(wheels)
    if startsWith(wheels(index).name, 'yunlink_python-')
        continue;
    end
    copyfile(fullfile(wheels(index).folder, wheels(index).name), ...
        fullfile(wheelDir, wheels(index).name));
    copied = copied + 1;
end
if copied == 0
    error('yunlink:NoBindingWheels', 'No YunLink binding wheels were copied from %s.', bindingDir);
end

fprintf('Release bundle ready in %s (%d binding wheels)\n', bundleDir, copied);
end

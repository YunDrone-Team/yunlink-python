function outputFile = build_toolbox(outputFile, sdkWheel)
%BUILD_TOOLBOX Build the end-user YunLink Sunray MATLAB Toolbox.
%   build_toolbox() writes dist/yunlink-sunray-matlab-1.1.0.mltbx.
%   An optional SDK wheel path selects the pure-Python yunlink-python wheel.

if nargin < 1 || strlength(string(outputFile)) == 0
    outputFile = fullfile(fileparts(fileparts(mfilename('fullpath'))), ...
        'dist', 'yunlink-sunray-matlab-1.1.0.mltbx');
else
    outputFile = char(string(outputFile));
end
if nargin < 2
    sdkWheel = '';
else
    sdkWheel = char(string(sdkWheel));
end

root = fileparts(mfilename('fullpath'));
repoRoot = fileparts(root);
outputDirectory = fileparts(outputFile);
if ~isempty(outputDirectory) && ~isfolder(outputDirectory)
    mkdir(outputDirectory);
end

stage = tempname(tempdir);
mkdir(stage);
cleanup = onCleanup(@() remove_stage(stage)); %#ok<NASGU>

% Public wrappers are the only MATLAB source files copied from the source tree.
wrappers = dir(fullfile(root, 'yunlink_*.m'));
toolboxFiles = strings(0, 1);
for index = 1:numel(wrappers)
    source = fullfile(wrappers(index).folder, wrappers(index).name);
    destination = fullfile(stage, wrappers(index).name);
    copyfile(source, destination);
    toolboxFiles(end + 1) = string(destination); %#ok<AGROW>
end

copy_required(fullfile(root, 'README.md'), fullfile(stage, 'README.md'));
copy_required(fullfile(root, 'getting_started.m'), fullfile(stage, 'getting_started.m'));
copy_required(fullfile(root, 'getting_started.html'), fullfile(stage, 'getting_started.html'));
copy_required(fullfile(repoRoot, 'LICENSE'), fullfile(stage, 'LICENSE'));
toolboxFiles(end + 1) = string(fullfile(stage, 'README.md'));
toolboxFiles(end + 1) = string(fullfile(stage, 'getting_started.m'));
toolboxFiles(end + 1) = string(fullfile(stage, 'getting_started.html'));
toolboxFiles(end + 1) = string(fullfile(stage, 'LICENSE'));

exampleDirectory = fullfile(stage, 'examples');
mkdir(exampleDirectory);
examples = dir(fullfile(root, 'examples', '*.m'));
for index = 1:numel(examples)
    destination = fullfile(exampleDirectory, examples(index).name);
    copyfile(fullfile(examples(index).folder, examples(index).name), destination);
    toolboxFiles(end + 1) = string(destination); %#ok<AGROW>
end

wheel = choose_sdk_wheel(repoRoot, sdkWheel);
if strlength(wheel) > 0
    vendorDirectory = fullfile(stage, 'vendor');
    mkdir(vendorDirectory);
    destination = fullfile(vendorDirectory, char(string(get_filename(wheel))));
    copyfile(char(wheel), destination);
    toolboxFiles(end + 1) = string(destination);
else
    warning('yunlink:MissingSdkWheel', ...
        'No yunlink-python wheel was found; the setup wizard will ask the user to select one.');
end

opts = matlab.addons.toolbox.ToolboxOptions(stage, 'yunlink-sunray');
opts.ToolboxName = 'YunLink Sunray MATLAB Support';
opts.ToolboxVersion = '1.1.0';
opts.AuthorName = 'YunDrone Team';
opts.Summary = 'MATLAB wrappers for controlling Sunray vehicles through YunLink';
opts.Description = ['Connect to a YunLink Bridge, inspect UAV state, and issue ', ...
    'basic Sunray control commands from MATLAB.'];
opts.MinimumMatlabRelease = 'R2026a';
opts.ToolboxFiles = cellstr(toolboxFiles);
opts.ToolboxMatlabPath = stage;
opts.ToolboxGettingStartedGuide = fullfile(stage, 'getting_started.m');
opts.OutputFile = outputFile;
matlab.addons.toolbox.packageToolbox(opts);
fprintf('Created %s\n', outputFile);
end

function wheel = choose_sdk_wheel(repoRoot, requested)
if ~isempty(requested)
    if ~isfile(requested)
        error('yunlink:InvalidSdkWheel', 'SDK wheel does not exist: %s', requested);
    end
    wheel = string(requested);
    return;
end
candidates = dir(fullfile(repoRoot, 'dist', 'yunlink_python-*.whl'));
if isempty(candidates)
    wheel = "";
elseif numel(candidates) == 1
    wheel = string(fullfile(candidates(1).folder, candidates(1).name));
else
    error('yunlink:MultipleSdkWheels', ...
        'Multiple SDK wheels found. Pass the desired wheel as the second argument.');
end
end

function name = get_filename(path)
[~, name, extension] = fileparts(char(path));
name = [name, extension];
end

function copy_required(source, destination)
if ~isfile(source)
    error('yunlink:MissingPackageFile', 'Required Toolbox file is missing: %s', source);
end
copyfile(source, destination);
end

function remove_stage(stage)
if isfolder(stage)
    rmdir(stage, 's');
end
end

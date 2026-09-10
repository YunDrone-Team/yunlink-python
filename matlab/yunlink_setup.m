function result = yunlink_setup(varargin)
%YUNLINK_SETUP Configure Python and install YunLink MATLAB dependencies.
%
%   yunlink_setup opens a file-selection wizard. The explicit forms
%   yunlink_setup(PYTHON, SDK) and yunlink_setup(PYTHON, SDK, BINDING) are
%   intended for scripts and CI. BINDING may be a wheel or package path.

if nargin == 0
    if ~usejava('desktop') || ~usejava('awt')
        error('yunlink:SetupRequiresDesktop', ...
            ['yunlink_setup with no arguments needs the MATLAB desktop. ', ...
             'Pass python, sdk, and optional binding paths instead.']);
    end
    [pythonExecutable, sdkSource, bindingSource] = select_sources();
elseif nargin == 2 || nargin == 3
    pythonExecutable = string(varargin{1});
    sdkSource = string(varargin{2});
    if nargin == 3
        bindingSource = string(varargin{3});
    else
        bindingSource = "";
    end
else
    error('yunlink:InvalidArguments', ...
        'Use yunlink_setup, yunlink_setup(python, sdk), or yunlink_setup(python, sdk, binding).');
end

pythonExecutable = string(pythonExecutable);
sdkSource = string(sdkSource);
bindingSource = string(bindingSource);
if strlength(pythonExecutable) == 0 || strlength(sdkSource) == 0
    error('yunlink:InvalidArguments', 'Python executable and SDK source must not be empty.');
end

environment = pyenv;
if string(environment.Status) == "Loaded"
    loadedExecutable = string(environment.Executable);
    if ~same_path(loadedExecutable, pythonExecutable)
        error('yunlink:PythonAlreadyLoaded', ...
            'MATLAB is already using %s. Restart MATLAB before selecting %s.', ...
            loadedExecutable, pythonExecutable);
    end
else
    pyenv('Version', char(pythonExecutable));
end

pythonExecutable = string(pyenv().Executable);
check_supported_python(pythonExecutable);
if strlength(bindingSource) > 0
    install_package(pythonExecutable, bindingSource, 'YunLink binding');
end
install_package(pythonExecutable, sdkSource, 'yunlink-python SDK');

addpath(fileparts(mfilename('fullpath')));
result = verify_installation(pythonExecutable, sdkSource, bindingSource);
fprintf('YunLink MATLAB setup complete with %s\n', char(pythonExecutable));
end

function [pythonExecutable, sdkSource, bindingSource] = select_sources()
environment = pyenv;
pythonExecutable = "";
if string(environment.Status) == "Loaded"
    choice = questdlg(sprintf('MATLAB is already using %s. Use it?', ...
        char(environment.Executable)), 'YunLink Python', ...
        'Use current', 'Choose another', 'Use current');
    if isempty(choice)
        error('yunlink:SetupCancelled', 'YunLink setup was cancelled.');
    end
    if strcmp(choice, 'Use current')
        pythonExecutable = string(environment.Executable);
    end
end
if strlength(pythonExecutable) == 0
    [name, folder] = uigetfile({'python*;*.exe', 'Python executable'}, ...
        'Select a Python 3.10, 3.11, 3.12, or 3.13 executable');
    if isequal(name, 0)
        error('yunlink:SetupCancelled', 'YunLink setup was cancelled.');
    end
    pythonExecutable = string(fullfile(folder, name));
end

root = fileparts(mfilename('fullpath'));
embedded = dir(fullfile(root, 'vendor', 'yunlink_python-*.whl'));
if numel(embedded) == 1
    sdkSource = string(fullfile(embedded(1).folder, embedded(1).name));
else
    sdkSource = "";
end
bindingSource = "";

choice = questdlg('How do you want to provide the platform YunLink binding?', ...
    'YunLink binding', 'Select wheel', 'Select bundle folder', 'Skip');
if isempty(choice)
    error('yunlink:SetupCancelled', 'YunLink setup was cancelled.');
elseif strcmp(choice, 'Select wheel')
    [name, folder] = uigetfile({'*.whl', 'YunLink binding wheel'}, ...
        'Select the platform-specific YunLink binding wheel');
    if isequal(name, 0)
        error('yunlink:SetupCancelled', 'YunLink binding selection was cancelled.');
    end
    bindingSource = string(fullfile(folder, name));
elseif strcmp(choice, 'Select bundle folder')
    folder = uigetdir(pwd, 'Select the YunLink MATLAB release bundle folder');
    if isequal(folder, 0)
        error('yunlink:SetupCancelled', 'YunLink bundle selection was cancelled.');
    end
    bindingSource = match_binding_wheel(folder, pythonExecutable);
    if strlength(sdkSource) == 0
        sdkSource = match_sdk_wheel(folder);
    end
end

if strlength(sdkSource) == 0
    [name, folder] = uigetfile({'*.whl;*.tar.gz;*', 'yunlink-python package or source'}, ...
        'Select the yunlink-python package or source file');
    if isequal(name, 0)
        error('yunlink:SetupCancelled', 'yunlink-python selection was cancelled.');
    end
    sdkSource = string(fullfile(folder, name));
end
end

function install_package(pythonExecutable, source, label)
command = sprintf('%s -m pip install --upgrade %s', ...
    shell_quote(char(pythonExecutable)), shell_quote(char(source)));
[status, output] = system(command);
if status ~= 0
    error('yunlink:InstallFailed', '%s installation failed:\n%s', label, output);
end
fprintf('%s installed.\n%s', label, output);
end

function result = verify_installation(pythonExecutable, sdkSource, bindingSource)
try
    binding = py.importlib.import_module('yunlink');
    sdk = py.importlib.import_module('yunlink_python');
catch exception
    error('yunlink:ImportFailed', ...
        'Python packages were installed but could not be imported: %s', exception.message);
end
result = struct();
result.pythonExecutable = char(pythonExecutable);
result.sdkSource = char(sdkSource);
result.bindingSource = char(bindingSource);
result.sdkVersion = python_version(sdk);
result.bindingVersion = python_version(binding);
fprintf('yunlink version: %s\nyunlink-python version: %s\n', ...
    result.bindingVersion, result.sdkVersion);
end

function version = python_version(module)
try
    version = char(string(py.getattr(module, '__version__')));
catch
    version = 'unknown';
end
end

function value = shell_quote(value)
value = ['"', strrep(value, '"', '\\"'), '"'];
end

function equal = same_path(first, second)
equal = strcmpi(strtrim(char(first)), strtrim(char(second)));
end

function wheel = match_sdk_wheel(directory)
files = list_wheels(directory, 'yunlink_python-*.whl');
if isempty(files)
    wheel = "";
elseif numel(files) == 1
    wheel = string(fullfile(files(1).folder, files(1).name));
else
    error('yunlink:MultipleSdkWheels', ...
        'Multiple yunlink-python wheels were found in %s. Select one file instead.', directory);
end
end

function wheel = match_binding_wheel(directory, pythonExecutable)
files = list_wheels(directory, 'yunlink-*.whl');
keep = false(numel(files), 1);
abi = python_abi_tag(pythonExecutable);
for index = 1:numel(files)
    name = lower(string(files(index).name));
    if startsWith(name, "yunlink_python-")
        continue;
    end
    keep(index) = matches_platform(name) && contains(name, abi);
end
files = files(keep);
if numel(files) == 0
    error('yunlink:BindingNotFound', ...
        'No YunLink binding wheel matching this computer and %s was found in %s.', ...
        abi, directory);
elseif numel(files) > 1
    error('yunlink:MultipleBindingWheels', ...
        'Multiple matching YunLink binding wheels were found in %s. Select one file instead.', directory);
end
wheel = string(fullfile(files(1).folder, files(1).name));
end

function files = list_wheels(directory, pattern)
files = dir(fullfile(directory, pattern));
entries = dir(directory);
for index = 1:numel(entries)
    if ~entries(index).isdir || startsWith(entries(index).name, '.')
        continue;
    end
    extra = dir(fullfile(entries(index).folder, entries(index).name, pattern));
    files = [files; extra]; %#ok<AGROW>
end
end

function matched = matches_platform(name)
if ispc
    matched = contains(name, "win");
elseif ismac
    arch = computer('arch');
    if contains(arch, 'arm') || strcmp(arch, 'maca64')
        matched = contains(name, "macosx") && (contains(name, "arm64") || contains(name, "aarch64"));
    else
        matched = contains(name, "macosx") && contains(name, "x86_64");
    end
else
    matched = contains(name, "manylinux") || contains(name, "linux");
end
end

function check_supported_python(pythonExecutable)
tag = python_abi_tag(pythonExecutable);
allowed = ["cp310", "cp311", "cp312", "cp313"];
if ~any(tag == allowed)
    error('yunlink:UnsupportedPython', ...
        'YunLink MATLAB supports Python 3.10, 3.11, 3.12, and 3.13. Selected %s.', tag);
end
end

function tag = python_abi_tag(pythonExecutable)
command = sprintf('%s -c "import sys; print(f''cp{sys.version_info.major}{sys.version_info.minor}'')"', ...
    shell_quote(char(pythonExecutable)));
[status, output] = system(command);
if status ~= 0
    error('yunlink:PythonProbeFailed', 'Could not read the Python version:\n%s', output);
end
tag = string(strtrim(output));
end

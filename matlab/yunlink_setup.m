function result = yunlink_setup(varargin)
%YUNLINK_SETUP Configure Python and install YunLink MATLAB dependencies.
%
%   yunlink_setup(PYTHON, BUNDLE_DIR) is the normal path: PYTHON is a
%   3.10-3.13 executable, BUNDLE_DIR is the unzipped release folder.
%   yunlink_setup(PYTHON, SDK, BINDING) installs explicit wheel paths.
%   yunlink_setup with no arguments still opens the file-selection wizard.

if nargin == 0
    if ~usejava('desktop') || ~usejava('awt')
        error('yunlink:SetupRequiresDesktop', ...
            ['yunlink_setup with no arguments needs the MATLAB desktop. ', ...
             'Prefer examples/ex00_setup.m: fill pythonExe and bundleDir, then Run.']);
    end
    [pythonExecutable, sdkSource, bindingSource] = select_sources();
elseif nargin == 2 || nargin == 3
    pythonExecutable = string(varargin{1});
    second = string(varargin{2});
    if isfolder(second)
        check_supported_python(pythonExecutable);
        bindingSource = match_binding_wheel(second, pythonExecutable);
        sdkSource = match_sdk_wheel(second);
        if strlength(sdkSource) == 0
            error('yunlink:MissingSdkWheel', ...
                'No yunlink_python-*.whl was found in %s', second);
        end
    else
        sdkSource = second;
        if nargin == 3
            bindingSource = string(varargin{3});
        else
            bindingSource = "";
        end
    end
else
    error('yunlink:InvalidArguments', ...
        ['Use examples/ex00_setup.m, yunlink_setup(python, bundleDir), ', ...
         'or yunlink_setup(python, sdk, binding).']);
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
if nargin == 0
    offer_examples();
end
end

function offer_examples()
if ~usejava('desktop') || ~usejava('awt')
    fprintf('Run yunlink_examples after setup to open the sample scripts.\n');
    return
end
choice = questdlg(sprintf([ ...
    'Setup finished.\n\n', ...
    'Open the MATLAB example folder now?\n', ...
    'You can edit and run read_state_demo.m from Current Folder.']), ...
    'YunLink examples', 'Open examples', 'Later', 'Open examples');
if strcmp(choice, 'Open examples')
    yunlink_examples();
else
    fprintf('Later, run yunlink_examples to open the sample scripts.\n');
end
end

function [pythonExecutable, sdkSource, bindingSource] = select_sources()
environment = pyenv;
pythonExecutable = "";
if string(environment.Status) == "Loaded"
    loaded = string(environment.Executable);
    if ~python_is_supported(loaded)
        error('yunlink:UnsupportedPython', ...
            ['MATLAB 已经加载了不支持的 Python：\n%s\n当前版本是 %s。\n\n', ...
             'YunLink 只支持 3.10、3.11、3.12、3.13，不能用 MATLAB 或 Homebrew 默认的 3.14。\n', ...
             '请完全退出 MATLAB 后重新打开，再运行 yunlink_setup，\n', ...
             '选择例如 /opt/homebrew/bin/python3.13 或 Windows 上的 python.exe（3.10-3.13）。'], ...
            loaded, python_abi_tag(loaded));
    end
    choice = questdlg(sprintf('MATLAB is already using %s. Use it?', ...
        char(environment.Executable)), 'YunLink Python', ...
        'Use current', 'Choose another', 'Use current');
    if isempty(choice)
        error('yunlink:SetupCancelled', 'YunLink setup was cancelled.');
    end
    if strcmp(choice, 'Use current')
        pythonExecutable = loaded;
    end
end
if strlength(pythonExecutable) == 0
    if ispc
        filterSpec = {'*.exe', 'Python executable (*.exe)'};
    else
        filterSpec = {'*', 'Python executable'};
    end
    [name, folder] = uigetfile(filterSpec, ...
        'Select Python 3.10-3.13 (not MATLAB 3.14), e.g. /opt/homebrew/bin/python3.13');
    if isequal(name, 0)
        error('yunlink:SetupCancelled', 'YunLink setup was cancelled.');
    end
    pythonExecutable = string(fullfile(folder, name));
end
check_supported_python(pythonExecutable);

root = fileparts(mfilename('fullpath'));
embedded = dir(fullfile(root, 'vendor', 'yunlink_python-*.whl'));
if numel(embedded) == 1
    sdkSource = string(fullfile(embedded(1).folder, embedded(1).name));
else
    sdkSource = "";
end
bindingSource = "";

choice = questdlg(sprintf([ ...
    'Install the YunLink native library next.\n\n', ...
    'Choose Select bundle folder and pick the unzipped release directory.\n', ...
    'Do not choose Skip.']), ...
    'YunLink binding', ...
    'Select bundle folder', 'Select wheel', 'Skip', 'Select bundle folder');
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
command = sprintf('%s%s -m pip install --upgrade --disable-pip-version-check %s', ...
    clean_env_prefix(), shell_quote(char(pythonExecutable)), shell_quote(char(source)));
[status, output] = system(command);
if status == 0
    fprintf('%s installed.\n%s', label, output);
    return
end
if isfile(source) && endsWith(lower(string(source)), ".whl")
    fprintf('%s pip failed; installing the wheel without pip.\n%s\n', label, output);
    extract_wheel(pythonExecutable, source);
    fprintf('%s extracted.\n', label);
    return
end
error('yunlink:InstallFailed', '%s installation failed:\n%s', label, output);
end

function extract_wheel(pythonExecutable, wheel)
script = [tempname, '.py'];
fid = fopen(script, 'w');
if fid < 0
    error('yunlink:InstallFailed', 'Could not write a temporary wheel installer.');
end
cleaner = onCleanup(@() delete_if_present(script));
fprintf(fid, [ ...
    'import pathlib, site, sys, zipfile\n', ...
    'wheel = pathlib.Path(sys.argv[1])\n', ...
    'dest = pathlib.Path(site.getsitepackages()[0])\n', ...
    'dest.mkdir(parents=True, exist_ok=True)\n', ...
    'zipfile.ZipFile(wheel).extractall(dest)\n', ...
    'print("extracted", wheel, "->", dest)\n']);
fclose(fid);
command = sprintf('%s%s %s %s', clean_env_prefix(), ...
    shell_quote(char(pythonExecutable)), shell_quote(script), shell_quote(char(wheel)));
[status, output] = system(command);
if status ~= 0
    error('yunlink:InstallFailed', 'Wheel extract failed:\n%s', output);
end
fprintf('%s\n', output);
end

function delete_if_present(path)
if exist(path, 'file')
    delete(path);
end
end

function prefix = clean_env_prefix()
if ispc
    prefix = '';
else
    prefix = ['env -u DYLD_LIBRARY_PATH -u DYLD_FALLBACK_LIBRARY_PATH ', ...
              '-u DYLD_INSERT_LIBRARIES -u DYLD_FRAMEWORK_PATH '];
end
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
        ['No YunLink binding wheel matching this computer and %s was found in %s.\n', ...
         'Python 3.14 (cp314) is not supported. Use 3.10, 3.11, 3.12, or 3.13.'], ...
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

function supported = python_is_supported(pythonExecutable)
tag = python_abi_tag(pythonExecutable);
supported = any(tag == ["cp310", "cp311", "cp312", "cp313"]);
end

function check_supported_python(pythonExecutable)
tag = python_abi_tag(pythonExecutable);
if ~python_is_supported(pythonExecutable)
    error('yunlink:UnsupportedPython', ...
        ['YunLink MATLAB supports Python 3.10, 3.11, 3.12, and 3.13.\n', ...
         'Selected %s (%s).\nDo not use MATLAB''s bundled Python 3.14.\n', ...
         'On this Mac pick /opt/homebrew/bin/python3.13'], ...
        pythonExecutable, tag);
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

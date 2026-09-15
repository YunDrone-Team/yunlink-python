function yunlink_ensure_python(mode)
%YUNLINK_ENSURE_PYTHON 在调用 py.* 之前准备并检查 CPython。
%   yunlink_ensure_python()         要求已能 import yunlink_python
%   yunlink_ensure_python("engine") 只要求 MATLAB 能调用该解释器
%
%   成功后把解释器路径写入 prefdir，下次启动 MATLAB 仍能恢复。
%   MATLAB 不支持的 CPython 会在这里用中文说明原因，避免只看到
%   「Python 命令需要支持的 CPython 版本」。

if nargin < 1 || strlength(strtrim(string(mode))) == 0
    mode = "sdk";
else
    mode = lower(string(mode));
end

releaseId = string(version('-release'));
matlabTags = matlab_cpython_tags(releaseId);
sdkTags = ["cp310", "cp311", "cp312", "cp313"];
usable = intersect(matlabTags, sdkTags);
if isempty(usable)
    error('yunlink:MatlabTooOld', ...
        ['MATLAB %s 官方只支持 %s，本工具箱需要 CPython 3.10–3.13。\n', ...
         '请升级到 MATLAB R2022b 或更新，并安装 Python 3.10。'], ...
        releaseId, join(matlabTags, " / "));
end

executable = current_python_executable();
if strlength(executable) == 0
    executable = load_saved_python();
end
if strlength(executable) == 0 || ~isfile(char(executable))
    error('yunlink:PythonNotConfigured', ...
        ['还没有为 MATLAB 配置 Python。\n', ...
         '请先运行 examples/ex00_setup.m，选择 Python 3.10–3.13 的可执行文件。\n', ...
         '当前 MATLAB %s 与本工具箱的交集：%s。'], ...
        releaseId, join(usable, " / "));
end

tag = python_abi_tag(executable);
if ~any(tag == sdkTags)
    error('yunlink:UnsupportedPython', ...
        ['YunLink 需要 Python 3.10、3.11、3.12 或 3.13，当前是 %s（%s）。\n', ...
         '不要使用 MATLAB 自带的 3.14。'], ...
        executable, tag);
end
if ~any(tag == matlabTags)
    error('yunlink:PythonNotSupportedByMatlab', ...
        ['MATLAB %s 不能调用 %s（%s）。\n', ...
         '这就是「Python 命令需要支持的 CPython 版本」的原因。\n', ...
         'MATLAB %s 官方支持：%s。\n', ...
         '本工具箱可用：%s。\n', ...
         '请安装交集中的 Python，关闭 MATLAB 后重开，再运行 ex00_setup。'], ...
        releaseId, executable, tag, releaseId, ...
        join(matlabTags, " / "), join(usable, " / "));
end

pe = pyenv;
if string(pe.Status) == "Loaded"
    if ~same_exe(string(pe.Executable), executable)
        error('yunlink:PythonAlreadyLoaded', ...
            ['MATLAB 已经加载 %s，无法改成 %s。\n请关闭 MATLAB 后重开，再运行 ex00_setup。'], ...
            string(pe.Executable), executable);
    end
else
    try
        pyenv('Version', char(executable));
    catch exception
        rethrow_python_engine_error(exception, releaseId, executable, tag, matlabTags, usable);
    end
end

try
    py.importlib.import_module('sys');
catch exception
    rethrow_python_engine_error(exception, releaseId, executable, tag, matlabTags, usable);
end
save_python(executable);

if mode == "sdk"
    try
        py.importlib.import_module('yunlink_python');
    catch exception
        error('yunlink:SdkNotInstalled', ...
            ['MATLAB 已能调用 %s，但还没有 yunlink_python。\n', ...
             '请先运行 examples/ex00_setup.m 安装通信库。\n%s'], ...
            executable, exception.message);
    end
end
end

function tags = matlab_cpython_tags(releaseId)
switch char(releaseId)
    case '2022a'
        tags = ["cp38", "cp39"];
    case {'2022b', '2023a'}
        tags = ["cp38", "cp39", "cp310"];
    case {'2023b', '2024a'}
        tags = ["cp39", "cp310", "cp311"];
    case {'2024b', '2025a'}
        tags = ["cp310", "cp311", "cp312"];
    otherwise
        tags = ["cp310", "cp311", "cp312", "cp313"];
end
end

function executable = current_python_executable()
executable = "";
try
    value = string(pyenv().Executable);
    if strlength(value) > 0 && isfile(char(value))
        executable = value;
    end
catch
end
end

function path = python_config_path()
path = fullfile(prefdir, 'yunlink_python_executable.txt');
end

function executable = load_saved_python()
executable = "";
path = python_config_path();
if ~isfile(path)
    return
end
try
    lines = readlines(path);
    if ~isempty(lines)
        candidate = strtrim(string(lines(1)));
        if strlength(candidate) > 0 && isfile(char(candidate))
            executable = candidate;
        end
    end
catch
end
end

function save_python(executable)
try
    writelines(string(executable), python_config_path());
catch
end
end

function tag = python_abi_tag(pythonExecutable)
command = sprintf(['%s -c "import sys; print(''cp'' + str(sys.version_info.major)', ...
    ' + str(sys.version_info.minor))"'], shell_quote(char(pythonExecutable)));
[status, output] = system(command);
if status ~= 0
    error('yunlink:PythonProbeFailed', '无法读取 Python 版本：\n%s', output);
end
tag = string(strtrim(output));
end

function value = shell_quote(value)
value = ['"', strrep(value, '"', '\"'), '"'];
end

function equal = same_exe(first, second)
equal = strcmpi(resolved_path(first), resolved_path(second));
end

function path = resolved_path(value)
path = strtrim(char(string(value)));
if strlength(path) == 0
    return
end
try
    path = char(java.io.File(path).getCanonicalPath());
catch
end
end

function rethrow_python_engine_error(exception, releaseId, executable, tag, matlabTags, usable)
message = exception.message;
if contains(message, "CPython") || contains(message, "支持的") || contains(message, "supported")
    error('yunlink:PythonNotSupportedByMatlab', ...
        ['MATLAB %s 拒绝调用 %s（%s）。\n', ...
         '这就是「Python 命令需要支持的 CPython 版本」。\n', ...
         'MATLAB %s 官方支持：%s。\n本工具箱可用：%s。\n', ...
         '请安装交集中的 Python，关闭 MATLAB 后重开，再运行 ex00_setup。'], ...
        releaseId, executable, tag, releaseId, ...
        join(matlabTags, " / "), join(usable, " / "));
end
rethrow(exception);
end

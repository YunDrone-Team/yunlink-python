function yunlink_setup(pythonExecutable, sdkSource, varargin)
%YUNLINK_SETUP Configure MATLAB Python and install the SDK.
if nargin < 2
    error('yunlink:MissingArguments', ...
        'yunlink_setup requires pythonExecutable and sdkSource.');
end
pythonExecutable = string(pythonExecutable);
sdkSource = string(sdkSource);
if strlength(pythonExecutable) == 0 || strlength(sdkSource) == 0
    error('yunlink:InvalidArguments', ...
        'pythonExecutable and sdkSource must not be empty.');
end

environment = pyenv;
if string(environment.Status) == "Loaded"
    if string(environment.Executable) ~= pythonExecutable
        error('yunlink:PythonAlreadyLoaded', ...
            'Restart MATLAB before changing the Python executable.');
    end
else
    pyenv('Version', char(pythonExecutable));
end

python = char(string(pyenv().Executable));
% Optional third argument installs a matching YunLink binding first.
if ~isempty(varargin)
    if numel(varargin) > 1
        error('yunlink:InvalidArguments', 'At most one YunLink binding source is supported.');
    end
    bindingSource = char(string(varargin{1}));
    command = sprintf('"%s" -m pip install --upgrade "%s"', python, bindingSource);
    [status, output] = system(command);
    if status ~= 0
        error('yunlink:InstallFailed', 'YunLink binding installation failed:\n%s', output);
    end
end

command = sprintf('"%s" -m pip install --upgrade "%s"', python, char(sdkSource));
[status, output] = system(command);
if status ~= 0
    error('yunlink:InstallFailed', 'pip installation failed:\n%s', output);
end

addpath(fileparts(mfilename('fullpath')));
fprintf('YunLink Python SDK configured with %s\n', python);
end

function values = yunlink_load_example_env()
%YUNLINK_LOAD_EXAMPLE_ENV 读取 examples/yunlink.env（KEY=VALUE）。
%   不使用 python-dotenv。系统环境变量仍可覆盖本文件。
values = struct( ...
    'YUNLINK_ADDRESS', "", ...
    'YUNLINK_BRIDGE_ID', "", ...
    'YUNLINK_UAV', "", ...
    'YUNLINK_UGV', "", ...
    'YUNLINK_DISCOVER_TIMEOUT', "5");
path = locate_env_file();
if strlength(path) == 0 || ~isfile(char(path))
    return
end
text = fileread(char(path));
lines = splitlines(string(text));
for index = 1:numel(lines)
    line = strtrim(lines(index));
    if strlength(line) == 0 || startsWith(line, "#")
        continue
    end
    raw = char(line);
    if strncmp(raw, 'export ', 7)
        raw = strtrim(raw(8:end));
    end
    eq = find(raw == '=', 1, 'first');
    if isempty(eq)
        continue
    end
    key = strtrim(raw(1:eq-1));
    value = strtrim(raw(eq+1:end));
    if (startsWith(string(value), '"') && endsWith(string(value), '"')) || ...
            (startsWith(string(value), "'") && endsWith(string(value), "'"))
        value = value(2:end-1);
    end
    if isfield(values, key)
        values.(key) = string(value);
    end
end
end

function path = locate_env_file()
path = "";
here = fileparts(mfilename('fullpath'));
candidates = {
    fullfile(pwd, 'yunlink.env')
    fullfile(here, 'examples', 'yunlink.env')
    fullfile(here, 'yunlink.env')
    };
for index = 1:numel(candidates)
    if isfile(candidates{index})
        path = string(candidates{index});
        return
    end
end
end

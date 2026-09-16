function values = yunlink_load_example_env()
%YUNLINK_LOAD_EXAMPLE_ENV 读取示例目标配置。
%   顺序：系统环境变量覆盖文件。文件先找 yunlink.env，没有再读 yunlink.env.example。
%   两个文件都没有则报错。
values = struct( ...
    'YUNLINK_ADDRESS', "", ...
    'YUNLINK_BRIDGE_ID', "", ...
    'YUNLINK_UAV', "", ...
    'YUNLINK_UGV', "", ...
    'YUNLINK_DISCOVER_TIMEOUT', "5");
path = locate_env_file();
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
here = fileparts(mfilename('fullpath'));
roots = {
    pwd
    fullfile(here, 'examples')
    here
    };
names = {'yunlink.env', 'yunlink.env.example'};
for nameIndex = 1:numel(names)
    for rootIndex = 1:numel(roots)
        candidate = fullfile(roots{rootIndex}, names{nameIndex});
        if isfile(candidate)
            path = string(candidate);
            fprintf('示例配置：%s\n', path);
            return
        end
    end
end
error('yunlink:MissingEnv', ...
    ['没有找到 yunlink.env 或 yunlink.env.example。\n', ...
     '请在示例目录打开 yunlink.env.example，把连接地址和 entity_uid 写进去。\n', ...
     '也可以复制一份改名为 yunlink.env。']);
end

function result = yunlink_update(varargin)
%YUNLINK_UPDATE 更新 Python SDK 和原生 binding，行为与 yunlink_setup 相同。
if nargin == 0
    result = yunlink_setup();
else
    result = yunlink_setup(varargin{:});
end
end

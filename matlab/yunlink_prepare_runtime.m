function yunlink_prepare_runtime()
%YUNLINK_PREPARE_RUNTIME 加载 YunLink 原生库前的进程环境。
%   1. 设置 KMP_DUPLICATE_LIB_OK，避免 MATLAB 与 libomp 冲突。
%   2. 恢复上次 ex00_setup 保存的 Python，并检查本 MATLAB 是否支持它。
setenv('KMP_DUPLICATE_LIB_OK', 'TRUE');
yunlink_ensure_python();
end

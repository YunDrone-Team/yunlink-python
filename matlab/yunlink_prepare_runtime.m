function yunlink_prepare_runtime()
%YUNLINK_PREPARE_RUNTIME 加载 YunLink 原生库前的进程环境。
%   MATLAB 自带 OpenMP，和 Homebrew Python 扩展里的 libomp 会冲突。
%   必须在第一次 py.import 之前调用，否则进程可能直接退出。
setenv('KMP_DUPLICATE_LIB_OK', 'TRUE');
end

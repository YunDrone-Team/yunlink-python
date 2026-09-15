function yunlink_prepare_runtime()
%YUNLINK_PREPARE_RUNTIME Avoid MATLAB/OpenMP clashes when loading YunLink.
setenv('KMP_DUPLICATE_LIB_OK', 'TRUE');
end

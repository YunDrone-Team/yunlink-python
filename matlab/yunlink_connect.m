function client = yunlink_connect(address)
%YUNLINK_CONNECT Connect to a YunLink Bridge through yunlink_python.
yunlink_prepare_runtime();
sdk = py.importlib.import_module("yunlink_python");
client = sdk.connect(py.str(char(address)));
end

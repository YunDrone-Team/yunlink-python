function client = yunlink_connect(address)
%YUNLINK_CONNECT Connect to a YunLink Bridge through yunlink_python.
sdk = py.importlib.import_module("yunlink_python");
client = sdk.connect(string(address));
end

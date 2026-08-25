function client = yunlink_connect(address)
%YUNLINK_CONNECT Connect to a YunLink Bridge through yunlink_sunray.
sdk = py.importlib.import_module("yunlink_sunray");
client = sdk.connect(string(address));
end

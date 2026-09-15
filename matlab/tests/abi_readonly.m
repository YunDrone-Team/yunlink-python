%ABI_READONLY Setup one Python ABI and read live Bridge state. No flight.
% Env: YUNLINK_PYTHON, YUNLINK_BUNDLE, YUNLINK_ADDRESS, YUNLINK_UAV, YUNLINK_UGV

pythonBin = getenv('YUNLINK_PYTHON');
bundleDir = getenv('YUNLINK_BUNDLE');
address = getenv('YUNLINK_ADDRESS');
uavUid = getenv('YUNLINK_UAV');
ugvUid = getenv('YUNLINK_UGV');
if isempty(pythonBin) || isempty(bundleDir) || isempty(address)
    error('yunlink:AbiTestEnv', 'YUNLINK_PYTHON, YUNLINK_BUNDLE and YUNLINK_ADDRESS are required.');
end
if isempty(uavUid)
    uavUid = 'e-89c423-2-1';
end
if isempty(ugvUid)
    ugvUid = 'e-89c423-3-1';
end

root = fileparts(fileparts(mfilename('fullpath')));
addpath(root);
yunlink_prepare_runtime();
pyenv('Version', pythonBin);
pythonBin = string(pyenv().Executable);
fprintf('python=%s\n', pythonBin);

try
    py.importlib.import_module('yunlink');
    py.importlib.import_module('yunlink_python');
    fprintf('packages already importable\n');
catch
    fprintf('running yunlink_setup\n');
    yunlink_setup(char(pythonBin), bundleDir);
end

bridges = yunlink_discover(3);
assert(~isempty(bridges), 'discover empty');
fprintf('discover %s\n', bridges(1).discoveryId);

client = yunlink_connect(address);
cleaner = onCleanup(@() yunlink_close(client)); %#ok<NASGU>
infos = yunlink_entities(client);
assert(numel(infos) >= 2, 'expected UAV and UGV');
uav = yunlink_vehicle(client, uavUid);
ugv = yunlink_ugv(client, ugvUid);
pause(0.6);
us = yunlink_state(uav);
gs = yunlink_ugv_state(ugv);
assert(us.connected && us.fresh, 'UAV state not fresh');
assert(gs.connected && gs.fresh, 'UGV state not fresh');
fprintf('UAV z=%.3f landed=%d  UGV x=%.3f y=%.3f\n', ...
    us.position.z, us.landed, gs.position.x, gs.position.y);
fprintf('ABI_READONLY_OK %s\n', pythonBin);

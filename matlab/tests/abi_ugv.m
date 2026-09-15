%ABI_UGV UGV move/hold for one already-configured Python ABI. No UAV takeoff.
root = fileparts(fileparts(mfilename('fullpath')));
addpath(root);
yunlink_prepare_runtime();
pythonBin = getenv('YUNLINK_PYTHON');
if ~isempty(pythonBin)
    pyenv('Version', pythonBin);
end
address = getenv('YUNLINK_ADDRESS');
if isempty(address)
    address = '192.168.10.10:9696';
end
ugvUid = getenv('YUNLINK_UGV');
if isempty(ugvUid)
    ugvUid = 'e-89c423-3-1';
end
client = yunlink_connect(address);
cleaner = onCleanup(@() yunlink_close(client)); %#ok<NASGU>
ugv = yunlink_ugv(client, ugvUid);
pause(0.5);
start = yunlink_ugv_state(ugv);
assert(start.fresh, 'UGV state not fresh');
fprintf('start x=%.3f y=%.3f\n', start.position.x, start.position.y);
yunlink_ugv_move_to(ugv, start.position.x + 0.12, start.position.y, 30);
yunlink_ugv_hold(ugv, 8);
finish = yunlink_ugv_state(ugv);
fprintf('finish x=%.3f y=%.3f\n', finish.position.x, finish.position.y);
fprintf('ABI_UGV_OK %s\n', string(pyenv().Executable));

function result = yunlink_velocity_control(vehicle, vx, vy, vz, options)
%YUNLINK_VELOCITY_CONTROL Send a bounded velocity action.
if nargin < 4
    vz = 0;
end
if nargin < 5
    options = struct();
end

args = {'duration_s', option(options, 'duration_s', 1.0), ...
    'lease_ms', option(options, 'lease_ms', 1000), ...
    'timeout', option(options, 'timeout', 15), ...
    'wait', option(options, 'wait', true)};
if isfield(options, 'frame_id')
    args = [args, {'frame_id', char(string(options.frame_id))}]; %#ok<AGROW>
end
if isfield(options, 'height_lock_m')
    args = [args, {'height_lock_m', double(options.height_lock_m)}]; %#ok<AGROW>
end
result = vehicle.velocity(double(vx), double(vy), double(vz), pyargs(args{:}));
end

function value = option(options, name, fallback)
if isfield(options, name)
    value = options.(name);
else
    value = fallback;
end
end

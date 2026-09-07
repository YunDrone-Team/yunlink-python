function result = yunlink_command(vehicle, kind, options)
%YUNLINK_COMMAND Dispatch one of the finite high-level Sunray commands.
if nargin < 3
    options = struct();
end
kind = lower(string(kind));
switch kind
    case "takeoff"
        result = yunlink_takeoff(vehicle, option(options, 'height_m', 1.5), option(options, 'timeout', 30));
    case "position"
        result = yunlink_position_control(vehicle, options.x, options.y, options.z, ...
            option(options, 'yaw_rad', 0), option(options, 'timeout', 120));
    case "velocity"
        result = yunlink_velocity_control(vehicle, options.vx, options.vy, ...
            option(options, 'vz', 0), options);
    case "hover"
        result = yunlink_hover(vehicle);
    case "return_home"
        result = yunlink_return_home(vehicle, option(options, 'timeout', 120));
    case "land"
        result = yunlink_land(vehicle);
    case "emergency_lock"
        result = yunlink_emergency_lock(vehicle, option(options, 'confirm', false), ...
            option(options, 'timeout', 20));
    otherwise
        error('yunlink:UnsupportedCommand', 'Unsupported command: %s', kind);
end
end

function value = option(options, name, fallback)
if isfield(options, name)
    value = options.(name);
else
    value = fallback;
end
end

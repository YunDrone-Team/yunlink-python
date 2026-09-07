function history = yunlink_monitor(vehicle, duration_s, options)
%YUNLINK_MONITOR Poll and return readable UAV state structs.
if nargin < 2
    duration_s = 30;
end
if nargin < 3
    options = struct();
end
period_s = option(options, 'period_s', 0.2);
callback = option(options, 'callback', []);
print_state = option(options, 'print', true);
if period_s <= 0 || duration_s < 0
    error('yunlink:InvalidMonitorOptions', 'duration_s must be non-negative and period_s positive.');
end

count = max(1, floor(duration_s / period_s) + 1);
history = repmat(yunlink_state(vehicle), 1, count);
started = tic;
index = 0;
while index < count
    index = index + 1;
    current = yunlink_state(vehicle);
    history(index) = current;
    if print_state
        fprintf('t=%.2fs pos=(%.3f, %.3f, %.3f) battery=%g%% mode=%s landed=%d\n', ...
            toc(started), current.position.x, current.position.y, current.position.z, ...
            current.batteryPercent, current.movementMode, current.landed);
    end
    if ~isempty(callback)
        callback(current);
    end
    if index >= count || toc(started) >= duration_s
        break;
    end
    pause(period_s);
end
history = history(1:index);
end

function value = option(options, name, fallback)
if isfield(options, name)
    value = options.(name);
else
    value = fallback;
end
end

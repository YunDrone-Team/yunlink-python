% 05_CANCEL_ACTION  开始移动后取消，再悬停降落。
%
% 做什么：演示 yunlink_cancel。会飞。
% 会不会飞：会。
% 本步要读：yunlink.env 的 YUNLINK_ADDRESS、YUNLINK_UAV。
% 上一步：ex04。下一步：ex06 无人车，或 ex12 全量检查。
%
% 起飞高度 1.0 米。非阻塞 move_to 目标在当前 x 再加 2.0 米（世界系）。
% 发出去后立刻 cancel，飞机不会走完那 2 米。

% 地址和 UAV entity_uid 来自 yunlink.env。
[address, uavUid] = yunlink_example_target();
% 起飞相对高度，单位米。
height = 1.0;

fprintf('本脚本会起飞，然后取消一次移动。\n');
client = yunlink_connect(address);
cleanup = onCleanup(@() yunlink_close(client));
uavUid = yunlink_example_pick(client, "sunray.uav", uavUid);
% attach，订阅遥测，仍未飞。
uav = yunlink_vehicle(client, uavUid);

try
    if yunlink_state(uav).landed
        fprintf('起飞\n');
        % 1.0：相对高度米。30：等待起飞结束的超时秒。
        yunlink_takeoff(uav, height, 30);
    end
    % 当前世界系位置，单位米。用来算 cancel 前的目标点。
    pos = yunlink_state(uav).position;
    fprintf('非阻塞 move_to，随后 cancel\n');
    % wait=false：命令发出后立刻返回，任务在后台跑。
    % pos.x + 2.0：目标 x，单位米（往前约 2 米）。
    % height：目标 z，单位米。
    % timeout=60：如果真的等，最多 60 秒；这里不等，所以几乎马上返回。
    uav.move_to(pos.x + 2.0, pos.y, height, pyargs('timeout', 60, 'wait', false));
    % 给 Bridge 一点点时间把任务发出去，再取消。0.4 是秒。
    pause(0.4);
    % 15：等待 cancel 完成的超时秒。
    yunlink_cancel(uav, 15);
    % 15：等待悬停完成的超时秒。
    yunlink_hover(uav, 15);
finally
    if ~yunlink_state(uav).landed
        fprintf('降落\n');
        % 30：等待降落结束的超时秒。
        yunlink_land(uav, 30);
    end
end
fprintf('完成。\n');

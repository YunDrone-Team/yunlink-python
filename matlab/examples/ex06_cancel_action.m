% 06_CANCEL_ACTION  启动一次移动后取消，再悬停降落。
% 本示例会发送飞行指令。

[address, envUav, envUgv] = yunlink_example_target();
uavUid = envUav;
height = 1.0;

client = yunlink_connect(address);
cleanup = onCleanup(@() yunlink_close(client));
uavUid = yunlink_example_pick(client, "sunray.uav", uavUid);
uav = yunlink_vehicle(client, uavUid);

try
    if yunlink_state(uav).landed
        fprintf('起飞\n');
        yunlink_takeoff(uav, height, 30);
    end
    pos = yunlink_state(uav).position;
    fprintf('开始移动并取消\n');
    uav.move_to(pos.x + 2.0, pos.y, height, pyargs('timeout', 60, 'wait', false));
    pause(0.4);
    yunlink_cancel(uav, 15);
    yunlink_hover(uav, 15);
finally
    if ~yunlink_state(uav).landed
        fprintf('降落\n');
        yunlink_land(uav, 30);
    end
end
fprintf('完成。\n');

%% YunLink Sunray MATLAB 快速开始
% 安装 Toolbox 后，先配置 Python，再连接 Bridge 读取状态。
% 不需要理解 YunLink 协议或 ROS。

%% 安装 Toolbox
% 在 MATLAB 中选择 Home → Add-Ons → Install from File，然后打开
% yunlink-sunray-matlab-1.1.0.mltbx。

%% 配置 Python
% 运行下面的命令。向导会选择 Python 3.10/3.11/3.12，安装平台对应的
% YunLink binding，并安装随 Toolbox 提供的 yunlink-python。
% 它不会连接设备，也不会发送飞行指令。
%
%   yunlink_setup

%% 连接并选择 UAV
% 把地址和实体 ID 换成你的 Bridge 实际值。
%
%   client = yunlink_connect("192.168.31.236:9696");
%   uav = yunlink_vehicle(client, "uav1");

%% 读取状态
%   state = yunlink_state(uav);
%   disp(state.position);
%   disp(state.batteryPercent);
%   disp(state.armed);
%   disp(state.landed);
%
% armed 和 disarmed 是只读状态。完整只读示例见 examples/read_state_demo.m。

%% 基础控制
% 第一次联通请使用直接位置、速度、悬停和降落。
% move_to 和 waypoint 属于 Planner 路径。
%
%   yunlink_takeoff(uav, 1.5);
%   yunlink_position_control(uav, 2.0, 0.0, 1.5);
%   yunlink_hover(uav);
%   yunlink_land(uav);
%   yunlink_close(client);
%
% 会发送飞行指令的示例见 examples/basic_flight_demo.m。

%% 状态监视
%   history = yunlink_monitor(uav, 10, struct("period_s", 0.2, "print", true));

%% 关闭连接
%   yunlink_close(client);
%   clear client uav;

%% 常见问题
% * 切换 Python 前需要重启 MATLAB。
% * YunLink binding wheel 必须匹配当前操作系统、CPU 和 Python 版本。
% * 连接失败时检查 Bridge 地址和实体 ID。
%
% 更完整的说明见 README.md，或运行 help yunlink_setup。

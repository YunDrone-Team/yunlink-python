%% YunLink Sunray MATLAB 快速开始
% 不要克隆代码仓库。请下载发布包：
%
%   https://github.com/YunDrone-Team/yunlink-python/releases/download/matlab-1.1.0/yunlink-sunray-matlab-1.1.0-bundle.zip

%% 安装 Toolbox
% 解压发布包。在 MATLAB 中选择 Home → Add-Ons → Install from File，
% 然后打开目录里的 yunlink-sunray-matlab-1.1.0.mltbx。

%% 配置一次
%   yunlink_setup
%
% 选择 Python 3.10、3.11 或 3.12，再选择 Select bundle folder，
% 选中解压后的目录。向导不会连接无人机。

%% 连接并读取状态
%   client = yunlink_connect("192.168.31.236:9696");
%   uav = yunlink_vehicle(client, "uav1");
%   state = yunlink_state(uav);
%   disp(state.position);
%   disp(state.batteryPercent);
%   disp(state.armed);
%   disp(state.landed);

%% 基础控制
%   yunlink_takeoff(uav, 1.5);
%   yunlink_position_control(uav, 2.0, 0.0, 1.5);
%   yunlink_hover(uav);
%   yunlink_land(uav);
%   yunlink_close(client);
%
% 完整说明见 README.md。

%% YunLink MATLAB 快速开始
% 下载发布包即可，不必克隆代码仓库：
%
%   https://github.com/YunDrone-Team/yunlink-python/releases/download/matlab-1.4.3/yunlink-sunray-matlab-1.4.3-bundle.zip

%% 安装 Toolbox
% 不要在 Add-On Explorer 中搜索。解压发布包后，在资源管理器、Finder
% 或文件管理器中双击 yunlink-sunray-matlab-1.4.3.mltbx，点击 Install。
% Add Package Repository 不是 .mltbx 安装入口。

%% 准备 Python
% MATLAB R2022b 或更新。Python 3.10–3.13（yunlink 绑定要求 ≥ 3.10）。
% 不要使用 MATLAB 自带 3.14。R2022a 不可用。
% 填写的是可执行文件路径，例如：
%   Windows:  C:\Users\<用户>\AppData\Local\Programs\Python\Python313\python.exe
%   macOS:    /opt/homebrew/bin/python3.13  或  /usr/local/bin/python3.13
%   Linux:    /usr/bin/python3.12

%% 配置一次
%   yunlink_examples
% 打开 ex00_setup.m，填写 pythonExe 和 bundleDir，点击 Run。
% 然后按 ex01_discover.m、ex02_connect_and_inspect.m、ex03_watch_state.m 的顺序运行。
% 完整列表见 examples/README.md。

%% 连接并读取状态
%   client = yunlink_connect("192.168.31.236:9696");
%   uav = yunlink_vehicle(client, "e-f97f96-2-1");
%   state = yunlink_state(uav);

%% 基础控制
%   yunlink_takeoff(uav, 1.5);
%   yunlink_position_control(uav, 2.0, 0.0, 1.5);
%   yunlink_hover(uav);
%   yunlink_land(uav);
%   yunlink_close(client);
%
% 完整说明见 README.md。

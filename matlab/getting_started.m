%% YunLink Sunray MATLAB 快速开始
% 不要克隆代码仓库。请下载发布包：
%
%   https://github.com/YunDrone-Team/yunlink-python/releases/download/matlab-1.1.0/yunlink-sunray-matlab-1.1.0-bundle.zip

%% 安装 Toolbox
% 不要在 Add-On Explorer 中搜索本工具箱。它只搜索 MathWorks 在线商店，
% 找不到 YunLink 是正常的；Add Package Repository 也不是本地安装入口。
% 解压发布包，在 macOS Finder 或 Windows 资源管理器中双击
% 目录里的 yunlink-sunray-matlab-1.1.0.mltbx。
% MATLAB 会打开 Toolbox 安装器；确认名称后点击 Install。
% Add-Ons 面板里的 Add Package Repository 不用于安装 .mltbx。

%% 准备 Python
% Windows 和 macOS 需要先安装 Python 3.10、3.11、3.12 或 3.13。
% MATLAB 不会自动安装 Python。
%
% macOS 终端：
%   python3 --version
%   which python3
%
% Windows PowerShell：
%   python --version
%   where python
%
% 记下 Python 可执行文件路径，不是安装目录。

%% 配置一次
%   yunlink_setup
%
% 选择刚才确认过的 Python 可执行文件，再选择 Select bundle folder，
% 选中解压后的目录。不要选 Skip。向导不会连接无人机。
% 配置后运行 pyenv，确认 Version 和 Executable 与终端检查结果一致。

%% 连接并读取状态
% 地址用 ip:port。第二个参数用 entity_uid，不要只用显示名 uav1。
%   client = yunlink_connect("192.168.31.236:9696");
%   uav = yunlink_vehicle(client, "e-f97f96-2-1");
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

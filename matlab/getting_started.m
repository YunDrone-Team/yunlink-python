%% YunLink MATLAB 快速开始
% 下载发布包即可，不必克隆代码仓库：
%
%   https://github.com/YunDrone-Team/yunlink-python/releases/download/matlab-1.4.5/yunlink-sunray-matlab-1.4.5-bundle.zip
%
% 用 MATLAB 学本工具箱：按编号跑 examples，不要先抄函数。

%% 安装 Toolbox
% 不要在 Add-On Explorer 中搜索。解压发布包后，在资源管理器、Finder
% 或文件管理器中双击 yunlink-sunray-matlab-1.4.5.mltbx，点击 Install。
% Add Package Repository 不是 .mltbx 安装入口。

%% 准备 Python
% MATLAB R2022b 或更新。Python 3.10–3.13（yunlink 绑定要求 ≥ 3.10）。
% 不要使用 MATLAB 自带 3.14。R2022a 不可用。
% 填写的是可执行文件路径，例如：
%   Windows:  C:\Users\<用户>\AppData\Local\Programs\Python\Python313\python.exe
%   macOS:    /opt/homebrew/bin/python3.13  或  /usr/local/bin/python3.13
%   Linux:    /usr/bin/python3.12

%% 教程入口：yunlink_examples
%   yunlink_examples
% 打开 ex00_setup.m，填写 pythonExe 和 bundleDir，点击 Run。
% 然后按编号跑：
%   ex00  配 Python（不连飞机）
%   ex01  搜索 Bridge，抄连接地址和 entity_uid
%   ex02  连接，只看目录
%   ex03  attach，只读状态。fresh=1 才能飞
%   ex04  会飞：起飞约 1 m，短移，降落
%   ex05  会飞：取消动作
%   ex06  会走：无人车
%   ex07  看错误
%   ex08  多 Bridge 时按 Bridge ID 选
%   ex09–ex11  多机只读 / 刷遥测
%   ex12  现场全量检查（会飞）
% 完整表格见 examples/README.md。目标写在 yunlink.env。
% 自己写脚本时查阅 API.md。逐步说明书 Typst 源码见 docs/README.md，Release 提供 PDF。

%% 看完 example 后再自己写
%   client = yunlink_connect("192.168.31.236:9696");
%   uav = yunlink_vehicle(client, "e-f97f96-2-1");
%   state = yunlink_state(uav);
%   yunlink_takeoff(uav, 1.5);   % 1.5 是相对高度，单位米
%   yunlink_hover(uav);
%   yunlink_land(uav);
%   yunlink_close(client);
%
% 完整说明见 README.md。

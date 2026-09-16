1.4.2：直控平移后先悬停再交航点；Planner 未就绪时等 15 秒并给出明确错误。

1.4.1：现场检查会起飞、短航线、降落、无人车点位。不限仿真。桌面确认默认「继续飞」。

1.4.0：增加 yunlink_live_check / ex99_live_check。没有 yunlink.env 时读 yunlink.env.example。

1.3.2：示例改用 yunlink.env；打印带 entity_uid 表头；写清 Windows 防火墙与 UDP 9697 搜索。

1.3.1：Windows 解压多一层目录时仍能找到 cp313 win_amd64 wheel；搜索忽略 ICMP RST；示例默认连搜到的 Bridge。

1.3.0：跟进最新 yunlink（含 Livox 点云累积 MappingStart/Stop）。MATLAB R2022b + Python 3.10 起。

MATLAB 用户请下载这个 zip，不必克隆仓库。

解压后：

1. 双击 `.mltbx`，在 MATLAB Toolbox 安装器中点击 Install
2. 在 MATLAB 中运行 `yunlink_examples`
3. 打开 `ex00_setup.m`，填写本机 Python 3.10–3.13 可执行文件路径和本 zip 的解压目录，然后 Run
4. 把 `examples/yunlink.env.example` 复制为 `yunlink.env`，把 `ex01_discover` 打印的连接地址和 entity_uid 填进去

需要系统已安装 Python 3.10、3.11、3.12 或 3.13，以及已经运行的 YunLink Bridge。不要使用 MATLAB 自带的 Python 3.14。

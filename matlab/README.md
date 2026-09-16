# YunLink MATLAB 使用说明

通过 MATLAB 控制 Sunray 无人机时，从本仓库的 GitHub Release 下载用户包即可。不必克隆源码。本仓库的 Release 仅用于 MATLAB 用户包。

发布包：

https://github.com/YunDrone-Team/yunlink-python/releases/download/matlab-1.4.5/yunlink-sunray-matlab-1.4.5-bundle.zip

MATLAB 通过本机 Python 调用 YunLink。连接对象是 **YunLink Bridge**，不是飞控本身。

**最低 MATLAB：R2022b。最低 Python：3.10。** 原因：底层 [yunlink](https://github.com/YunDrone-Team/yunlink) 绑定要求 CPython ≥ 3.10。R2022a 官方只有 3.8/3.9，对不上就会报「Python 命令需要支持的 CPython 版本」。这不是搜索失败，是 MATLAB 拒绝调用该解释器。

发布包已经包含预编译的通信库。用户需要本机安装 Python 3.10–3.13，但不需要克隆或编译 `yunlink` C++ 仓库。`ex00_setup.m` 会把包内的两个 Python wheel 装进该 Python：

1. `yunlink-2.0.1-*.whl`：按操作系统和 Python 版本提供的原生绑定
2. `yunlink_python-1.3.0-*.whl`：MATLAB 调用的 SDK

MATLAB 本身不内置可用的 3.10–3.13 解释器，所以仍要指定系统里的 Python 可执行文件。通信库不在 MATLAB 里现场编译。

## 环境要求

- MATLAB **R2022b 或更新版本**
- Windows、macOS 或 Linux 上已安装 **该 MATLAB 官方支持的 CPython 3.10–3.13**
- 正在运行的 YunLink Bridge，以及目标设备的 `entity_uid`

不要使用 MATLAB 自带的 Python 3.14。需要的是系统里安装的 Python **可执行文件**，不是安装目录。

MATLAB 只会调用它官方支持的 CPython。版本对不上时会出现「Python 命令需要支持的 CPython 版本」。请先运行 `ex00_setup`，并按下表选解释器：

| MATLAB | 本工具箱可用的 Python |
| --- | --- |
| R2022a | 不可用（官方只有 3.8/3.9，没有对应通信库） |
| R2022b / R2023a | 3.10 |
| R2023b / R2024a | 3.10、3.11 |
| R2024b / R2025a | 3.10、3.11、3.12 |
| R2025b / R2026a | 3.10、3.11、3.12、3.13 |

Win11 上 Miniconda 的 `python.exe` 若是 3.12，而 MATLAB 是 R2022a，就会被拒绝。请升级 MATLAB，或安装上表中的 Python 后**重启 MATLAB**再跑 `ex00_setup`。命令请写 `ex01_discover`，不要带 `.m`。

公开方法对照见仓库 [`docs/API_CN.md`](../docs/API_CN.md)。MATLAB 每个封装函数见 [`developer/API.md`](developer/API.md)；安装进 Toolbox 后同目录也有 `API.md`。

## 搜索原理与 Windows 防火墙

搜索 **不是** 去连 TCP 9696。本机向 **UDP 9697** 发查询：`255.255.255.255`、网卡广播地址、以及本网段 `/24` 里每个 IP。不少 Wi-Fi 会丢掉有限广播，所以 SDK 会补单播。Bridge 用 9697 回答，然后再用 TCP 9696 建 Session。

Windows 第一次运行 MATLAB 或 `python.exe` 时，可能弹出全屏「Windows 安全警报」。请勾选 **专用网络** 并允许访问。点取消或只允许公用网络，就会搜不到或偶发失败。

也可以跳过搜索：在示例目录把 `yunlink.env.example` 复制为 `yunlink.env`，写入 `YUNLINK_ADDRESS=ip:9696`。地址用 `ex01_discover` 打印的「连接地址」，不要用文档里的示例 IP。

目标飞机/无人车的 ID 叫 **entity_uid**（例如 `e-52c218-2-1`），不是显示名 `uav1`。写入 `YUNLINK_UAV=` / `YUNLINK_UGV=`。

常见路径：

| 系统 | 示例 |
| --- | --- |
| Windows | `C:\Users\<用户名>\AppData\Local\Programs\Python\Python313\python.exe` |
| macOS | `/opt/homebrew/bin/python3.13` 或 `/usr/local/bin/python3.13` |
| Linux | `/usr/bin/python3.12` |

在系统终端确认版本：

```text
Windows:    python --version
            where python
macOS:      python3.13 --version
            which python3.13
Linux:      python3 --version
            which python3
```

若 `python` / `python3` 显示 3.14，请改用带版本号的可执行文件，例如 `python3.13` 或 `Python313\python.exe`。

## 安装 Toolbox

Add-On Explorer 只搜索 MathWorks 商店，搜索不到本工具箱是正常的。不要在里面搜索，也不要使用 **Add Package Repository**。

1. 下载并解压发布包。不要在压缩包内部直接操作。
2. 在资源管理器、Finder 或文件管理器中双击 `yunlink-sunray-matlab-1.4.5.mltbx`。
3. MATLAB 打开 Toolbox 安装器后，确认名称为 **YunLink Sunray MATLAB Support**，点击 Install。
4. 若双击没有唤起 MATLAB，可在命令窗口执行：

```matlab
matlab.addons.install("完整路径/yunlink-sunray-matlab-1.4.5.mltbx")
```

路径按本机实际情况填写。Windows 使用反斜杠或正斜杠均可。

## 配置 Python 与通信库

安装 Toolbox 后，在 MATLAB 命令窗口运行：

```matlab
yunlink_examples
```

当前文件夹会切到示例目录。先打开并运行 `ex00_setup.m`：

1. 填写 `pythonExe`（上表中的 Python 3.10–3.13 可执行文件）。
2. 填写 `bundleDir`（解压后的发布包目录）。若留空，脚本会在用户下载目录中查找。
3. 点击编辑器中的 **Run**。

`ex00_setup.m` 会安装匹配当前系统和 Python 版本的通信库，然后打开 `ex01_discover.m`。这一步不连接无人机。

在编辑器中打开 `.m` 文件后，先保存，再点绿色 **Run**（或 F5）。输出在下方 Command Window。也可以在 Command Window 直接输入脚本名，例如 `ex01_discover`。需要停止时用红色 **Stop** 或 Ctrl-C。详细对应关系见 [`examples/README.md`](examples/README.md)。

配置完成后可用下面命令检查：

```matlab
pyenv
```

`Version` 应为 3.10、3.11、3.12 或 3.13。若 MATLAB 已经加载了其他 Python，请关闭 MATLAB 后重新打开，再运行 `ex00_setup.m`。

## 连接模型

MATLAB 不提供独立的设备搜索。请先从地面站或 Python 示例 `01_discover.py` 取得地址和设备 ID。

| 字段 | 用途 |
| --- | --- |
| Bridge 地址 `host:port` | 传给 `yunlink_connect`，例如 `192.168.31.236:9696` |
| `entity_uid` | 传给 `yunlink_vehicle`，例如 `e-f97f96-2-1` |
| 显示名 `uav1` | 仅供阅读；多设备时不要当作唯一 ID |

`yunlink_connect` 只连接 Bridge，不会 attach 设备。
`yunlink_vehicle(client, entity_uid)` 才会 attach 并订阅状态。
`yunlink_takeoff` 等函数才会申请控制权并发送动作。

## 使用

将地址和 `entity_uid` 换成现场确认过的值：

```matlab
client = yunlink_connect("192.168.31.236:9696");
uav = yunlink_vehicle(client, "e-f97f96-2-1");

state = yunlink_state(uav);
disp(state.position);
disp(state.batteryPercent);
disp(state.armed);
disp(state.landed);
disp(state.fresh);

yunlink_takeoff(uav, 1.5);
yunlink_position_control(uav, 2.0, 0.0, 1.5);
yunlink_hover(uav);
yunlink_land(uav);

yunlink_close(client);
```

示例脚本按编号排列，说明见 [`examples/README.md`](examples/README.md)。运行 `yunlink_examples` 后，在 Current Folder 中按 `ex00_setup.m` → `ex01_discover.m` → `ex02_connect_and_inspect.m` 的顺序执行。控制类示例从 `ex04_flight_basics.m` 开始。

运行示例前先修改其中的地址和 `entity_uid`。`state.armed` / `state.disarmed` 只表示状态，没有解锁或上锁函数。`state.fresh` 为 false 时不要起飞。

推荐顺序：完成 `ex00_setup.m` → 只读 `read_state_demo.m` → 确认状态新鲜后再运行控制示例。

## 常用函数

| 函数 | 作用 |
| --- | --- |
| `yunlink_examples` | 打开示例目录 |
| `yunlink_setup` | 配置 Python 和通信库；一般通过 `ex00_setup.m` 调用 |
| `yunlink_discover` | 搜索局域网中的 Bridge |
| `yunlink_connect` | 连接 Bridge，不 attach 设备 |
| `yunlink_entities` | 读取设备目录，不 attach |
| `yunlink_vehicle` | 按 `entity_uid` attach 无人机 |
| `yunlink_ugv` | 按 `entity_uid` attach 无人车 |
| `yunlink_state` | 读取状态 |
| `yunlink_takeoff` | 起飞 |
| `yunlink_move_to` | Planner 单目标移动 |
| `yunlink_waypoint` | Planner 航点 |
| `yunlink_position_control` | 直接位置控制 |
| `yunlink_velocity_control` | 速度控制 |
| `yunlink_hover` | 悬停 |
| `yunlink_land` | 降落 |
| `yunlink_cancel` | 取消当前动作 |
| `yunlink_monitor` | 监视状态一段时间 |
| `yunlink_close` | 关闭连接 |
| `yunlink_update` | 更新依赖 |

返航和紧急上锁需要明确调用。紧急上锁必须确认：

```matlab
yunlink_return_home(uav);
yunlink_emergency_lock(uav, true);
```

## 更新

下载新的发布包，重新安装 `.mltbx`，然后再次运行 `ex00_setup.m`（或 `yunlink_update`），并选择新的解压目录。

## 常见问题

- **Add-On Explorer 搜不到：** 本工具箱不在 MathWorks 商店中。请双击本地 `.mltbx`。
- **报错 cp314 / Python 3.14：** 当前选中了不支持的 Python。请改为 3.10–3.13 的可执行文件，并在必要时重启 MATLAB。
- **PythonAlreadyLoaded：** MATLAB 已加载其他 Python。关闭 MATLAB 后重开，再运行 `ex00_setup.m`。
- **无法导入 yunlink：** 确认 `bundleDir` 指向解压后的整个发布包目录，且 Python 版本为 3.10–3.13。
- **连接失败：** 检查 Bridge 是否已启动，以及地址、端口、`entity_uid` 是否与现场一致。
- **平台：** Windows 64 位、macOS Apple Silicon、Linux x86_64。

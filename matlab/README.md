# YunLink Sunray MATLAB 用户指南

用 MATLAB 控制 Sunray 无人机时，只需要下载发布包，不要克隆代码仓库。

发布包：

https://github.com/YunDrone-Team/yunlink-python/releases/download/matlab-1.1.0/yunlink-sunray-matlab-1.1.0-bundle.zip

MATLAB 底层调用的是 Python SDK。连接对象仍然是 **YunLink Bridge**，不是直接连飞控。

## 测试当天最短路径

1. 本机准备 Python 3.10–3.13。这台 Mac 用 `/opt/homebrew/bin/python3.13`，不要用 `python3` 或 MATLAB 自带 3.14。
2. 下载并解压上面的 zip。双击 `.mltbx` 点 Install。不要用 Add-On Explorer。
3. MATLAB 运行：

```matlab
addpath('/Users/groove/Project/work/YunDrone/yunlink-python/matlab')
yunlink_examples
```

4. 打开的 `00_setup.m` 里确认 `pythonExe` 和 `bundleDir`（可留空自动找 Downloads），点 **Run**。不要再空跑 `yunlink_setup` 点对话框。
5. 它会装依赖并打开 `read_state_demo.m`。改地址和 `entity_uid` 后运行。
6. 只读通过后再跑 `basic_flight_demo.m`。

## 你需要准备什么

- MATLAB R2026a 或更新版本
- Windows 或 macOS 本机已安装 Python 3.10、3.11、3.12 或 3.13
- 已经运行的 YunLink Bridge 地址，例如 `192.168.31.236:9696`
- 目标无人机的 `entity_uid`，例如 `e-f97f96-2-1`（不要只用显示名 `uav1` 当稳定 ID）

MATLAB 不会替你安装 Python。请先在系统终端确认版本和路径：

macOS：

```bash
python3 --version
which python3
```

Windows PowerShell：

```powershell
python --version
where python
```

确认版本为 3.10、3.11、3.12 或 3.13，并记下 **Python 可执行文件路径**，例如
`/opt/homebrew/bin/python3.13` 或
`C:\Users\你的用户名\AppData\Local\Programs\Python\Python312\python.exe`。
向导中选择这个可执行文件，不是选择 Python 安装目录。

## 安装 Toolbox（图形界面）

> **你看到的 Add-On Explorer 不是本地安装器。** 它只搜索 MathWorks 在线商店，搜索不到
> `YunLink Sunray MATLAB Support` 是正常的。请关闭这个页面，不要搜索本工具箱，也不要点击
> **Add Package Repository**。

1. 下载并解压 `yunlink-sunray-matlab-1.1.0-bundle.zip`。不要直接在 zip 压缩包内操作。
2. 打开解压后的目录，找到 `yunlink-sunray-matlab-1.1.0.mltbx`。
3. 在 macOS Finder 或 Windows 资源管理器中**双击这个 `.mltbx` 文件**。MATLAB 会自动打开 Toolbox 安装器。
4. 在安装器中确认名称为 **YunLink Sunray MATLAB Support**，点击 **Install/安装**。
5. 回到 MATLAB，在命令窗口运行：

```matlab
yunlink_setup
```

6. 选择刚才确认过的 Python 可执行文件。
7. 弹出 “How do you want to provide the platform YunLink binding?” 时，选 **Select bundle folder**，并选中刚才解压出来的目录。不要选 Skip。

向导会自动安装匹配当前系统和 Python 版本的通信库。它不会连接无人机，也不会发送飞行指令。

配置后可在 MATLAB 中检查实际使用的 Python：

```matlab
pyenv
py.importlib.import_module("yunlink")
py.importlib.import_module("yunlink_python")
```

确认 `Version` 是 3.10、3.11、3.12 或 3.13，`Executable` 与终端中检查的路径一致。

如果 MATLAB 已经加载了别的 Python，先重启 MATLAB，再运行 `yunlink_setup`。

> **不要使用 Add Package Repository。** 这是 MATLAB 的文件夹型包仓库功能，不用于安装 `.mltbx`。
> 如果双击没有唤起 MATLAB，也可以在 MATLAB 命令窗口执行
> `matlab.addons.install("/完整路径/yunlink-sunray-matlab-1.1.0.mltbx")`。

## Bridge 和设备 ID

MATLAB 没有独立的搜索函数。地址和设备 ID 请先用 Python 示例或地面站确认：

```text
探测候选 ID  f97f96@192.168.31.236:9696   地面站探测列表用，MATLAB 不用它去连接
Bridge 地址  192.168.31.236:9696          传给 yunlink_connect
Bridge ID    f97f96                      只用来区分多台 Bridge
entity_uid   e-f97f96-2-1                传给 yunlink_vehicle
显示名       uav1                        仅供阅读，多机时不要当唯一 ID
```

`yunlink_connect` 只连接 Bridge，不会 attach 无人机。
`yunlink_vehicle(client, entity_uid)` 才会 attach 并订阅状态。
后面的 `yunlink_takeoff` 才会申请控制权并发送动作。

## 使用

把地址和 `entity_uid` 换成你刚才确认的值：

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

只读示例：`examples/read_state_demo.m`。先改文件里的地址和设备 ID，再运行。
会发送飞行指令的示例：`examples/basic_flight_demo.m`。

`state.armed` 和 `state.disarmed` 只表示状态，没有解锁/上锁控制函数。
`state.fresh` 为 false 时不要起飞，先检查 Bridge 和设备是否在发布状态。

## 建议测试顺序

1. `yunlink_setup` 和 `pyenv` 检查。
2. `yunlink_connect` + `yunlink_vehicle` + `yunlink_state`（只读，不飞）。
3. 确认 `state.connected`、`state.fresh`、位置和电池在更新。
4. 现场允许后：`yunlink_takeoff` → `yunlink_hover` → `yunlink_land`。
5. 需要再测：`yunlink_position_control`、`yunlink_velocity_control`、`yunlink_move_to`、`yunlink_waypoint`、`yunlink_cancel`。

## 常用函数

| 函数 | 作用 |
| --- | --- |
| `yunlink_setup` | 首次配置 Python 和通信库 |
| `yunlink_examples` | 打开 MATLAB 示例目录，可直接看到并运行脚本 |
| `yunlink_connect` | 连接 Bridge，不 attach 设备 |
| `yunlink_vehicle` | 按 entity_uid 选择并 attach 无人机 |
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

下载新的发布包，重新安装 `.mltbx`，然后运行：

```matlab
yunlink_update
```

再次选择解压后的新目录即可。

## 常见问题

- 报错 `cp314`：选成了 Python 3.14。在 `00_setup.m` 里把 `pythonExe` 写成 `/opt/homebrew/bin/python3.13`。
- 报错 `pyexpat` / `_XML_SetAllocTrackerActivationThreshold`：MATLAB 调 pip 时带入了系统旧 libexpat。请运行仓库里的 `00_setup.m`（会清掉 DYLD 并在 pip 失败时直接解压 wheel）。
- 不要用命令窗口空跑 `yunlink_setup` 点对话框。日常入口是 `00_setup.m`。
- 找不到 Python：先在 Windows 或 macOS 安装 Python 3.10、3.11、3.12 或 3.13；不要使用 MATLAB 自带的 3.14。
- 版本或路径不一致：在终端重新运行 `python --version`/`which python3`（Windows 使用 `where python`），并在向导中选择同一个可执行文件。
- `PythonAlreadyLoaded`：重启 MATLAB 后再配置。
- 无法导入 `yunlink`：确认选择的是解压后的整个 bundle 目录，且 Python 版本是 3.10、3.11、3.12 或 3.13。
- 当前 macOS 包支持 Apple Silicon；Linux 支持 x86_64；Windows 支持 64 位。
- 连接失败：检查 Bridge 是否已启动，以及地址、端口、`entity_uid` 是否正确。
- 搜不到设备：MATLAB 本身不搜索；先用 Python `examples/01_discover.py` 拿到 `ip:port` 和 `entity_uid`。
- `uav1` 连错机：多设备时改用完整 `entity_uid`，例如 `e-f97f96-2-1`。

# YunLink Sunray MATLAB 用户指南

用 MATLAB 控制 Sunray 无人机时，只需要下载发布包，不要克隆代码仓库。

发布包：

https://github.com/YunDrone-Team/yunlink-python/releases/download/matlab-1.1.0/yunlink-sunray-matlab-1.1.0-bundle.zip

## 你需要准备什么

- MATLAB R2026a 或更新版本
- Windows 或 macOS 本机已安装 Python 3.10、3.11、3.12 或 3.13
- 已经运行的 YunLink Bridge 地址，例如 `192.168.31.236:9696`

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
`/opt/homebrew/bin/python3.12` 或
`C:\Users\你的用户名\AppData\Local\Programs\Python\Python312\python.exe`。
向导中选择这个可执行文件，不是选择 Python 安装目录。

## 安装

1. 下载并解压 `yunlink-sunray-matlab-1.1.0-bundle.zip`。
2. 打开 MATLAB，选择 **Home → Add-Ons → Install from File**。
3. 选择解压目录里的 `yunlink-sunray-matlab-1.1.0.mltbx`。
4. 在命令窗口运行：

```matlab
yunlink_setup
```

5. 选择刚才确认过的 Python 可执行文件。
6. 选择 **Select bundle folder**，并选中刚才解压出来的目录。

向导会自动安装匹配当前系统和 Python 版本的通信库。它不会连接无人机，也不会发送飞行指令。

配置后可在 MATLAB 中检查实际使用的 Python：

```matlab
pyenv
```

确认 `Version` 是 3.10、3.11、3.12 或 3.13，`Executable` 与终端中检查的路径一致。

如果 MATLAB 已经加载了别的 Python，先重启 MATLAB，再运行 `yunlink_setup`。

## 使用

把地址和飞机 ID 换成你的实际值：

```matlab
client = yunlink_connect("192.168.31.236:9696");
uav = yunlink_vehicle(client, "uav1");

state = yunlink_state(uav);
disp(state.position);
disp(state.batteryPercent);
disp(state.armed);
disp(state.landed);

yunlink_takeoff(uav, 1.5);
yunlink_position_control(uav, 2.0, 0.0, 1.5);
yunlink_hover(uav);
yunlink_land(uav);

yunlink_close(client);
```

只读示例：`examples/read_state_demo.m`。
会发送飞行指令的示例：`examples/basic_flight_demo.m`。

`state.armed` 和 `state.disarmed` 只表示状态，没有解锁/上锁控制函数。

## 常用函数

| 函数 | 作用 |
| --- | --- |
| `yunlink_setup` | 首次配置 |
| `yunlink_connect` | 连接 Bridge |
| `yunlink_vehicle` | 选择无人机 |
| `yunlink_state` | 读取状态 |
| `yunlink_takeoff` | 起飞 |
| `yunlink_position_control` | 直接位置控制 |
| `yunlink_velocity_control` | 速度控制 |
| `yunlink_hover` | 悬停 |
| `yunlink_land` | 降落 |
| `yunlink_cancel` | 取消当前动作 |
| `yunlink_monitor` | 监视状态 |
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

- 找不到 Python：先在 Windows 或 macOS 安装 Python 3.10、3.11、3.12 或 3.13；不要使用 MATLAB 自带的 3.14。
- 版本或路径不一致：在终端重新运行 `python --version`/`which python3`（Windows 使用 `where python`），并在向导中选择同一个可执行文件。
- `PythonAlreadyLoaded`：重启 MATLAB 后再配置。
- 无法导入 `yunlink`：确认选择的是解压后的整个 bundle 目录，且 Python 版本是 3.10、3.11、3.12 或 3.13。
- 当前 macOS 包支持 Apple Silicon；Linux 支持 x86_64；Windows 支持 64 位。
- 连接失败：检查 Bridge 是否已启动，以及地址、端口、飞机 ID 是否正确。

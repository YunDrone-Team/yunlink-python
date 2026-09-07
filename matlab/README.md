# YunLink Sunray MATLAB 支持

本目录是轻量 MATLAB 包装层。它通过 MATLAB Python Interface 调用
`yunlink-python`，不复制 YunLink Wire，也不连接 ROS。

## 启动 MATLAB

桌面模式：

```bash
matlab -desktop
```

无界面执行示例：

```bash
matlab -batch "run('matlab/examples/basic_flight_demo.m')"
```

R2026a 推荐使用 `-batch` 做自动化验证和打包。它不启动桌面，不需要
Computer Use，并会把错误作为非零退出码返回：

```bash
MATLAB=/Applications/MATLAB_R2026a.app/bin/matlab
cd /absolute/path/to/yunlink-python

# 只检查 MATLAB 包装文件，不连接 Bridge，也不发送飞行动作。
"$MATLAB" -batch "run('matlab/tests/run_tests.m')"

# 构建 MATLAB Toolbox。
"$MATLAB" -batch "addpath('matlab'); build_toolbox"
```

也可以指定输出文件：

```bash
"$MATLAB" -batch "addpath('matlab'); build_toolbox('/tmp/yunlink-sunray.mltbx')"
```

R2026a 还提供 `matlab.addons.toolbox.ToolboxOptions`、
`matlab.addons.toolbox.packageToolbox`、`matlab.addons.install` 和
`matlab.addons.uninstall`，适合在 CI 或脚本中完成 Toolbox 的构建、安装和清理。

第一次在 MATLAB 中加载 Python 前，选择一个 Python 3.10、3.11 或 3.12 环境：

```matlab
pyenv(Version="/absolute/path/to/python3.12");
```

R2026a 本机默认 Python 版本可能是 3.14；本 SDK 当前验证范围是 Python 3.10、3.11、
3.12，因此应显式指定受支持的解释器。也可以在 `-batch` 中验证 Python 边界：

```bash
"$MATLAB" -batch "pyenv('Version','/absolute/path/to/python3.12'); sdk=py.importlib.import_module('yunlink_python'); disp(string(py.getattr(sdk,'__version__')))"
```

Python 环境一旦进入 `Loaded` 状态，切换解释器需要重启 MATLAB。

## 安装

先安装与当前平台匹配的 YunLink binding，再安装本 SDK：

```matlab
yunlink_setup( ...
    "/absolute/path/to/python3.12", ...
    "/absolute/path/to/yunlink-python", ...
    "/absolute/path/to/yunlink/bindings/python");
```

如果 YunLink binding 已经安装：

```matlab
yunlink_setup( ...
    "/absolute/path/to/python3.12", ...
    "/absolute/path/to/yunlink-python");
```

也可以直接在 shell 中执行：

```bash
python -m pip install /path/to/yunlink/bindings/python
python -m pip install /path/to/yunlink-python
```

安装 Toolbox 发布包：

```matlab
matlab.addons.install("/path/to/yunlink-sunray.mltbx");
```

## 更新

更新源码或 wheel 后，在重启的 MATLAB 中执行：

```matlab
yunlink_update( ...
    "/absolute/path/to/python3.12", ...
    "/absolute/path/to/new/yunlink-python", ...
    "/absolute/path/to/new/yunlink/bindings/python");
```

更新后验证版本：

```matlab
sdk = py.importlib.import_module("yunlink_python");
disp(string(sdk.__version__));
```

## 最小控制示例

```matlab
client = yunlink_connect("192.168.31.236:9696");
uav = yunlink_vehicle(client, "uav1");

state = yunlink_state(uav);
disp(state);
disp(state.frameId);
disp(state.armed);      % 只读状态，不是控制调用
disp(state.disarmed);   % state.armed 的取反

yunlink_takeoff(uav, 1.5);
yunlink_position_control(uav, 2.0, 0.0, 1.5);
yunlink_hover(uav);
yunlink_return_home(uav);
yunlink_land(uav);

yunlink_close(client);
```

紧急上锁必须显式确认：

```matlab
yunlink_emergency_lock(uav, true);
```

状态监视返回 MATLAB struct 数组：

```matlab
history = yunlink_monitor(uav, 10, struct('period_s', 0.2));
```

`yunlink_state_raw(uav)` 可用于需要访问原始 Python 对象的高级脚本。

没有连接设备的 MATLAB 包装层 smoke check：

```bash
matlab -batch "run('matlab/tests/run_tests.m')"
```

连接正在运行的测试 Bridge 做非 Planner 联通验证（不发送航点、不调用紧急上锁）：

```bash
YUNLINK_ADDRESS=192.168.31.236:9696 \
YUNLINK_ENTITY=uav1 \
"$MATLAB" -batch "addpath('matlab'); run('matlab/tests/home_connectivity.m')"
```

脚本会依次读取状态、起飞到 1 m、执行一次短距离直接位置控制、悬停并降落，
最后要求 `landed=true`。实体和地址通过环境变量覆盖，避免把设备选择写死在测试命令中。

构建 Toolbox：

```bash
matlab -batch "addpath('matlab'); build_toolbox"
```

输出文件默认为 `dist/yunlink-sunray-matlab.mltbx`。

## 控制接口

| MATLAB 函数 | 作用 |
| --- | --- |
| `yunlink_takeoff` | 起飞 |
| `yunlink_position_control` | 直接位置控制 |
| `yunlink_move_to` | Planner 单航点移动 |
| `yunlink_velocity_control` | 速度控制 |
| `yunlink_waypoint` | 单航点任务 |
| `yunlink_hover` | 悬停 |
| `yunlink_return_home` | 返航任务 |
| `yunlink_land` | 降落 |
| `yunlink_cancel` | 取消当前动作 |
| `yunlink_emergency_lock` | 已确认的紧急上锁 |
| `yunlink_monitor` | 轮询状态 |

`yunlink_command` 只接受 `takeoff`、`position`、`velocity`、`hover`、
`return_home`、`land` 和 `emergency_lock`，不允许任意底层命令透传。

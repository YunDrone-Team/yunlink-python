# YunLink Sunray MATLAB 用户指南

这个 Toolbox 让 MATLAB 通过 YunLink Bridge 连接 Sunray 无人机。安装后直接在命令窗口调用函数即可，不需要理解 ROS、Wire 或 Protobuf。

## 安装

1. 打开 MATLAB。
2. 选择 **Home → Add-Ons → Install from File**。
3. 选择 `yunlink-sunray-matlab-1.1.0.mltbx`。
4. 安装完成后，在命令窗口运行：

```matlab
yunlink_setup
```

向导会引导你完成这些步骤：

1. 选择 Python 3.10、3.11 或 3.12 解释器。
2. 选择平台对应的 YunLink binding wheel，或选择发布 bundle 目录让向导自动匹配。
3. 安装 Toolbox 自带的 `yunlink-python` wheel。如果安装包里没有该 wheel，向导会让你手动选择。
4. 验证 `yunlink` 和 `yunlink_python` 可以导入。

向导只安装依赖，不会连接设备，也不会发送飞行指令。

MATLAB 已经加载 Python 后，不能在当前进程切换解释器。如果提示 `PythonAlreadyLoaded`，请重启 MATLAB 再运行 `yunlink_setup`。

## 连接和读取状态

把地址和实体 ID 换成你的 Bridge 实际值：

```matlab
client = yunlink_connect("192.168.31.236:9696");
uav = yunlink_vehicle(client, "uav1");

state = yunlink_state(uav);
disp(state.position);
disp(state.batteryPercent);
disp(state.px4Mode);
disp(state.armed);
disp(state.disarmed);
disp(state.landed);
```

`state.armed` 和 `state.disarmed` 只表示飞控当前状态。Toolbox 不提供 `yunlink_arm` 或 `yunlink_disarm`。

只读示例见 `examples/read_state_demo.m`。

## 基础控制

```matlab
yunlink_takeoff(uav, 1.5);
yunlink_velocity_control(uav, 0.2, 0.0, 0.0, struct("duration_s", 1.0));
yunlink_position_control(uav, 2.0, 0.0, 1.5);
yunlink_hover(uav);
yunlink_land(uav);
yunlink_close(client);
```

`position_control` 是直接位置控制。`move_to` 和 `waypoint` 会走 Planner，不属于第一次体验。

会发送飞行指令的完整示例见 `examples/basic_flight_demo.m`。运行前请确认连接的是允许测试的设备。

状态监视：

```matlab
history = yunlink_monitor(uav, 10, struct("period_s", 0.2, "print", true));
```

## 常用函数

| 函数 | 作用 |
| --- | --- |
| `yunlink_setup` | 首次配置 Python 和依赖 |
| `yunlink_connect` | 连接 Bridge |
| `yunlink_vehicle` | 选择 UAV |
| `yunlink_state` | 读取状态 |
| `yunlink_takeoff` | 起飞 |
| `yunlink_position_control` | 直接位置控制 |
| `yunlink_velocity_control` | 速度控制 |
| `yunlink_hover` | 悬停 |
| `yunlink_land` | 降落 |
| `yunlink_cancel` | 取消当前动作 |
| `yunlink_monitor` | 轮询状态 |
| `yunlink_close` | 关闭连接 |
| `yunlink_update` | 更新 Python 依赖 |

返航和紧急上锁需要明确调用。紧急上锁必须确认：

```matlab
yunlink_return_home(uav);
yunlink_emergency_lock(uav, true);
```

## 更新

安装新的 Toolbox 后，再运行一次配置：

```matlab
yunlink_update
```

它会打开和 `yunlink_setup` 相同的向导。

## 常见问题

- `PythonAlreadyLoaded`：重启 MATLAB，再选择目标 Python。
- 无法导入 `yunlink`：binding wheel 必须匹配当前操作系统、CPU 和 Python 版本。
- 连接失败：检查 Bridge 地址、网络和实体 ID。
- 状态不是最新：确认 Bridge 仍在发布 Mobility 状态。
- 无参数 `yunlink_setup` 需要 MATLAB 桌面。没有桌面时，使用 `yunlink_setup(python, sdk, binding)` 并传入三个路径。

# YunLink Python SDK 完整教程

这组示例从搜索 Bridge 开始，逐步完成连接、实体选择、状态读取、起飞、基础移动、目标移动、航点任务、取消和降落。
示例使用普通 Python，不连接 ROS；Python 只通过 YunLink 连接 SunrayV2 的 Bridge。

## 运行前准备

先安装 YunLink Python binding 和本 SDK：

```bash
python -m pip install ./yunlink/bindings/python
python -m pip install ./yunlink-python
```

或者使用已经安装的 `yunlink-python` wheel。示例默认读取以下环境变量：

```bash
export YUNLINK_ADDRESS=192.168.31.236:9696
export YUNLINK_VEHICLE=uav1
export YUNLINK_UGV=ugv1
```

不设置 `YUNLINK_ADDRESS` 时，搜索示例会使用 YunLink UDP discovery。网络不允许广播时，请直接设置地址。
设备名称既可以写 `uav1` 这样的显示名，也可以写目录返回的完整实体 UID。

**安全提醒：** `04_flight_basics.py`、`05_waypoints.py`、`06_cancel_action.py` 和 `07_ugv_control.py`
会发送真实控制动作。第一次运行请只连接仿真实体，确认周围没有人员和障碍物，并准备好随时停止仿真。

## 教程顺序

### 1. 搜索 Bridge

```bash
python examples/01_discover.py
```

它只发送 discovery 查询，不连接、不 attach、不控制设备。输出包含 Bridge 地址、Profile 和实体目录。

### 2. 连接并查看设备目录

```bash
python examples/02_connect_and_inspect.py
```

这个脚本建立 YunLink Session，读取实体目录，选择 UAV，并等待第一份状态快照。它还演示了 `client.raw`：
普通程序不需要使用它，但高级程序可以通过它访问底层 Transport。

### 2.1 多 Bridge 搜索、按 ID 选择连接

现实局域网中可能同时有很多台无人机或多个 Bridge。使用：

```bash
python examples/10_discover_select_connect.py
```

脚本会打印全部 Bridge，每个 Bridge 有唯一的 `endpoint_uid`，并列出其下挂的 UAV/UGV 及各自的 `entity_uid`。
交互输入 Bridge ID 或序号即可连接指定设备。自动化测试可以直接传 ID：

```bash
python examples/10_discover_select_connect.py --id f97f96 --entity e-f97f96-2-1
```

也可以设置 `YUNLINK_BRIDGE_ID` 和 `YUNLINK_ENTITY_ID`，避免交互输入。`endpoint_uid` 选择 Bridge，
`entity_uid` 选择 Bridge 下的具体 UAV/UGV；两级 ID 都会完整打印。连接后也可以使用输出的实体 UID 或名称调用 `client.vehicle(...)`。
搜索阶段不会控制任何设备。

搜索结果分两级：`endpoint_uid` 是 Bridge ID，`entity_uid` 是 Bridge 下面具体 UAV/UGV 的 ID。
不要把 IP 地址当作设备 ID；同一局域网可能有多台 Bridge，脚本会先列出全部结果，再让你选择。

### 3. 持续读取状态

```bash
python examples/03_watch_state.py --seconds 10
```

状态快照包含连接状态、位置、速度、解锁/着地状态、电池、飞控状态和 Planner 状态。也可以注册回调，
让状态变化主动推送到自己的程序中。

### 4. 起飞、前进、后退、左右/上下移动、目标移动、悬停、降落

```bash
python examples/04_flight_basics.py
```

流程是：起飞到安全高度，前进，后退，左移，右移，上移，下移，使用 Planner 移动到目标位置，悬停，最后降落。
基础方向动作是短时速度租约；租约结束时 Action 返回 `CANCELLED`，表示控制租约正常结束，不等于飞行失败。

### 5. 多航点任务

```bash
python examples/05_waypoints.py
```

`Waypoint` 使用当前 odometry frame，任务会等待 Planner 完成全部航点。脚本同时订阅状态，打印当前航点、距离、
停留时间和失败原因。

### 6. 非阻塞 Action 和取消

```bash
python examples/06_cancel_action.py --after 2
```

传入 `wait=False` 会得到 `ActionHandle`。可以查询 `phase`、`progress` 和 `detail`，也可以在任务执行中调用
`vehicle.cancel()`。如果本地没有动作句柄，`cancel()` 会调用 Planner 的幂等取消 RPC，因此也能取消其他会话提交的 Planner 任务。

### 7. 无人车

```bash
python examples/07_ugv_control.py
```

在现有协议支持范围内，示例演示无人车状态、MovePoint、速度租约和 Hold。它不会调用 UAV 的飞行接口。

### 7.1 多设备并行控制

```bash
python examples/11_multi_device_control.py
```

脚本会发现全部 UAV/UGV，并用线程并行提交各自的小动作。每个对象仍使用自己的 `entity_uid`；
SDK 不会自动编队、同步动作或把一台设备的失败传播给其他设备。

### 7.2 多 UAV 航线

```bash
python examples/12_multi_uav_waypoints.py
```

每台 UAV 获得一条独立的两点小航线，使用 `ActionHandle` 分别等待。这个例子是多设备控制示范，
不是 swarm/formation 控制器。

### 7.3 多设备状态监控

```bash
python examples/13_multi_device_state.py --seconds 60
```

只读取状态，不发送起飞、移动或降落动作，适合先确认目录和遥测链路。

### 8. 异常、超时和断线

```bash
python examples/08_errors.py
```

连接失败、实体不存在、权限不足、服务拒绝、动作超时和连接断开都会以 SDK 异常或 `ActionHandle` 结果暴露，
不会伪造成功。断线后 SDK 不会自动重放未完成的飞行动作，脚本必须明确决定是否重新提交。

### 9. 真实设备接入清单

运行真实飞行器前先阅读 [`09_real_device_checklist.md`](09_real_device_checklist.md)。仿真和真实设备使用同一套 SDK API，
但仿真不能替代真实飞控、定位、传感器和物理安全验收。

## 常用 API 对照

```python
from yunlink_python import Waypoint, connect, discover, discover_and_connect

bridges = discover(timeout=1.0)
with connect("192.168.31.236:9696") as client:
    uav = client.vehicle("uav1")
    uav.takeoff(height_m=1.5, timeout=30)
    uav.forward(speed_mps=0.2, duration_s=1.0)
    uav.backward(speed_mps=0.2, duration_s=1.0)
    uav.move_to(x=1.0, y=0.0, z=1.5, timeout=60)
    uav.waypoints([Waypoint(1.0, 0.0, 1.5), Waypoint(1.0, 1.0, 1.5)])
    uav.hover(timeout=15)
    uav.land(timeout=30)
```

`discover_and_connect()` 适合网络中只有一个 Bridge 的情况。多 Bridge 场景请运行
[`10_discover_select_connect.py`](10_discover_select_connect.py)，按搜索结果中的 `endpoint_uid`
选择目标，再调用 `connect_discovered()`；不要依赖模糊的 IP 或默认第一台设备。
`client.entities()`、`client.vehicles()` 和 `client.ugvs()` 返回目录快照，`client.raw` 保留底层 YunLink 入口。

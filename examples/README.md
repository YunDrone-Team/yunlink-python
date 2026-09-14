# YunLink Python SDK 完整教程

这组示例严格按照“搜索 Bridge、连接 Bridge、打印设备目录、显式选择设备、attach、读取状态、控制”的顺序组织。
示例使用普通 Python，不连接 ROS；Python 只通过 YunLink 连接 SunrayV2 的 Bridge。

最重要的边界：`connect()` 只连接 Bridge，`client.entities()` 只读取目录，只有
`client.vehicle(entity_uid)` 或 `client.ugv(entity_uid)` 才会 attach 具体设备。

## 运行前准备

先安装预编译的 YunLink Python binding，再安装本 SDK。binding 从
[yunlink v2.0.1](https://github.com/YunDrone-Team/yunlink/releases/tag/v2.0.1)
下载，不必编译 C++：

```bash
python -m pip install /path/to/yunlink-2.0.1-*.whl
python -m pip install --no-deps -e .
```

`--no-deps` 必须加，因为 `yunlink` 不在 PyPI。不要使用 `uv run`。

目标机器写在 `examples/yunlink.env`，所有示例共用这一份，不必每次 export：

```bash
cp examples/yunlink.env.example examples/yunlink.env
```

打开该文件，填入 `YUNLINK_ADDRESS` 和确认过的 `YUNLINK_UAV` / `YUNLINK_UGV`。
地址留空时，连接类示例会搜索唯一 Bridge；网络不允许广播或多台 Bridge 时必须填写地址。
`--address` / `--entity` 只用于临时覆盖。推荐使用完整 `entity_uid`，不要用列表序号。

**安全提醒：** `04_flight_basics.py`、`05_waypoints.py`、`06_cancel_action.py` 和 `07_ugv_control.py`
会发送真实控制动作。第一次运行请只连接仿真实体，确认周围没有人员和障碍物，并准备好随时停止仿真。

## 教程顺序

### 1. 搜索 Bridge

```bash
python examples/01_discover.py
```

它只发送 discovery 查询，不连接、不 attach、不控制设备。默认监听 5 秒，终端会显示 loading，
听满后再统一打印。可用 `--timeout 10` 或 `YUNLINK_DISCOVER_TIMEOUT` 加长。
输出按表格打印地面站同款探测候选 ID（`endpoint_uid@ip:tcp_port`）、Bridge ID，
以及每台设备的 `entity_uid` 和 GCS 键。

### 2. 连接 Bridge 并打印设备目录

```bash
python examples/02_connect_and_inspect.py
```

这个脚本只建立 YunLink Session 并读取实时实体目录，不 attach、不申请设备权限、不发送控制动作。
请记录输出的 `entity_uid`，作为下一步选择设备的明确 ID。

### 2.1 多 Bridge 搜索、按 ID 选择连接

现实局域网中可能同时有很多台无人机或多个 Bridge。使用：

```bash
python examples/10_discover_select_connect.py
```

脚本会打印全部 Bridge，每个 Bridge 有唯一的 `endpoint_uid`，并列出其下挂的 UAV/UGV 及各自的 `entity_uid`。
自动化测试必须通过 Bridge 的 `endpoint_uid` 选择目标：

```bash
python examples/10_discover_select_connect.py --id f97f96 --entity e-f97f96-2-1
```

也可以在 `examples/yunlink.env` 填写 `YUNLINK_BRIDGE_ID` 和 `YUNLINK_UAV`。
`endpoint_uid` 选择 Bridge，`entity_uid` 选择 Bridge 下的具体 UAV/UGV；两级 ID 都会完整打印。
缺少 ID 时脚本会退出，不会猜测目标或连接列表中的第一台设备。搜索和目录阶段不会控制任何设备。

搜索结果分两级：`endpoint_uid` 是 Bridge ID，`entity_uid` 是 Bridge 下面具体 UAV/UGV 的 ID。
不要把 IP 地址当作设备 ID；同一局域网可能有多台 Bridge，脚本会先列出全部结果，再让你选择。

### 3. 持续读取状态

```bash
python examples/03_watch_state.py --seconds 10
```

状态快照包含连接状态、位置、速度、解锁/着地状态、电池、飞控状态和 Planner 状态。也可以注册回调，
让状态变化主动推送到自己的程序中。

`state.armed` 和 `state.disarmed` 是只读状态，`state.landed`/`state.landing` 表示落地和降落阶段；
SDK 不提供 `arm()` 或 `disarm()` 控制调用。

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

### 7.4 只读全量观测（可与地面站同时使用）

```bash
python examples/14_observe_live.py
python examples/14_observe_live.py --entity <entity_uid>
```

只 attach 和订阅遥测，不申请控制权，不发送任何动作。默认观测目录里全部 UAV/UGV。
终端进入备用屏幕整页覆盖刷新（不会在滚动区里堆旧输出），中文表格显示有内容的字段，并统计刷新次数和遥测包数。
地面站可以同时控制同一架机。`--seconds 0`（默认）一直跑，Ctrl-C 退出。

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

bridges = discover(timeout=5)
with connect("192.168.31.236:9696") as client:
    # 这里必须填入前面目录中确认过的 UAV entity_uid。
    uav = client.vehicle("<entity_uid>")
    uav.takeoff(height_m=1.5, timeout=30)
    uav.forward(speed_mps=0.2, duration_s=1.0)
    uav.backward(speed_mps=0.2, duration_s=1.0)
    uav.move_to(x=1.0, y=0.0, z=1.5, timeout=60)
    uav.waypoints([Waypoint(1.0, 0.0, 1.5), Waypoint(1.0, 1.0, 1.5)])
    uav.hover(timeout=15)
    uav.land(timeout=30)
```

直接位置控制、返航和明确确认的紧急上锁：

```python
uav.position_control(1.0, 0.0, 1.5)
uav.return_home(timeout=120)
uav.emergency_lock(confirm=True)
```

`discover_and_connect()` 适合网络中只有一个 Bridge 的高级场景。多 Bridge 场景请运行
[`10_discover_select_connect.py`](10_discover_select_connect.py)，按搜索结果中的 `endpoint_uid`
选择目标，再调用 `connect_discovered()`；不要依赖模糊的 IP 或默认第一台设备。
`client.entities()`、`client.vehicles()` 和 `client.ugvs()` 返回目录快照，`client.raw` 保留底层 YunLink 入口。

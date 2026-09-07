# yunlink-python

`yunlink-python` 是面向 SunrayV2 的简洁 Python 控制 SDK。它通过 YunLink Bridge
连接无人机，不依赖 ROS，也不替代 Bridge。

```text
Python / MATLAB
      |
yunlink-python       Sunray 便捷接口
      |
yunlink              通用 YunLink Wire v2 Python 绑定
      |
YunLink ROS Bridge   ROS 与 YunLink 的边界
      |
SunrayV2
```

## 安装

当前 SDK 版本为 `1.1.0`。由于 `yunlink` 依赖包含平台相关的原生运行库，
请先安装与系统和 Python 版本匹配的 YunLink wheel，再安装本仓库的
`yunlink-python` wheel。两个包目前都不发布到 PyPI。

SDK wheel 和源码包可从 GitHub Release 下载；本地开发也可以直接按下方命令从源码安装。

开发环境可以从源码安装：

```bash
git clone --recursive https://github.com/YunDrone-Team/yunlink.git
python -m pip install ./yunlink/bindings/python

git clone https://github.com/YunDrone-Team/yunlink-python.git
python -m pip install ./yunlink-python
```

支持 Python 3.10、3.11 和 3.12。

完整中文使用手册见 [`docs/USAGE_GUIDE_CN.md`](docs/USAGE_GUIDE_CN.md)，文档索引见
[`docs/README.md`](docs/README.md)。

## 第一个完整流程

先搜索 Bridge，再连接 Bridge 并打印设备目录，最后使用明确的 `entity_uid` 选择 UAV。
连接 Bridge 本身不会 attach 或控制任何设备。

```python
from yunlink_python import connect

with connect("192.168.31.236:9696") as client:
    # 这里只连接 Bridge，并读取当前设备目录；不会 attach 或控制设备。
    for device in client.entities():
        print(device.uid, device.name, device.kind)

    # 将这里替换为上面确认过的 entity_uid 或设备名称。
    uav = client.vehicle("<entity_uid>")

    # 从这里开始才会 attach UAV，并在后续动作中申请控制权限。
    uav.takeoff(height_m=1.5, timeout=30)
    uav.move_to(x=2.0, y=0.0, z=1.5, timeout=60)
    uav.land(timeout=30)
```

搜索全部 Bridge：

```python
from yunlink_python import discover

for bridge in discover(timeout=1.5):
    print(f"Bridge ID: {bridge.endpoint_uid}")
    print(f"Address: {bridge.ip}:{bridge.tcp_port}")
    for device in bridge.entities:
        print(f"  Device ID: {device.entity_uid} ({device.kind})")
```

如果局域网中有多个 Bridge，请先运行
[`examples/10_discover_select_connect.py`](examples/10_discover_select_connect.py)，用
`endpoint_uid` 选择 Bridge，再用 `entity_uid` 选择设备。SDK 不会默认选择第一台设备。

## 航点和状态

```python
from yunlink_python import Waypoint, connect

with connect("192.168.31.236:9696") as client:
    # 这里使用目录中确认过的实体 ID；不要把 Bridge ID 当成设备 ID。
    vehicle = client.vehicle("<entity_uid>")

    unsubscribe = vehicle.on_state_changed(
        lambda state: print(state.position, state.battery_percent, state.planner)
    )
    vehicle.waypoints([
        Waypoint(1.0, 0.0, 1.5),
        Waypoint(2.0, 1.0, 1.5, hold_time_s=1.0),
    ])
    unsubscribe()
```

`vehicle.state` 是最新的不可变快照，包含位置、速度、飞行状态、电池和 Planner 状态。
`move_to()` 使用现有 Planner 的单航点任务，会等待 Planner 确认任务完成；它不是只把目标发布到 ROS。

状态还包括姿态四元数、角速度、定位状态、PX4 模式、控制模式、移动模式以及：

```python
state.armed       # Bridge 报告的只读状态
state.disarmed    # 只读派生属性，等于 not state.armed
state.landed
state.landing
```

`arm()` 和 `disarm()` 不作为 SDK 控制接口；SDK 不伪造或覆盖飞控的真实解锁状态。

## 直接控制与任务控制

```python
with connect("192.168.31.236:9696") as client:
    uav = client.vehicle("<entity_uid>")
    uav.takeoff(1.5)
    uav.position_control(2.0, 0.0, 1.5)  # 直接位置控制
    uav.velocity(0.2, 0.0, 0.0, duration_s=1.0)
    uav.hover()
    uav.return_home()
    uav.land()
```

`move_to()` 和 `waypoint()` 是 Planner 型任务；`position_control()` 是现有
`UavDirectControlGoal` 的直接位置控制，两者保持明确区分。`emergency_lock()` 是高风险动作，
必须显式传入 `confirm=True`：

```python
uav.emergency_lock(confirm=True)
```

为了便于脚本分发，`vehicle.command()` 只接受 `takeoff`、`position`、`velocity`、`hover`、
`return_home`、`land` 和 `emergency_lock` 七个命令名；未知命令会立即抛出 `ValueError`。

## 非阻塞动作

控制方法默认等待最终结果。传入 `wait=False` 可取得 `ActionHandle`：

```python
handle = vehicle.takeoff(1.5, wait=False)
print(handle.progress)
result = handle.wait(timeout=30)
```

`vehicle.cancel()` 取消最近仍在执行的 Action；没有本地句柄时会调用 Planner 的幂等取消接口，
因此也可以停止由其他会话提交的当前 Planner 任务。

断线后 SDK 会恢复 Session、Attach、权限和状态订阅，但不会重放未完成的飞行动作。
原 Action 会以 `DisconnectedError` 结束，必须由脚本明确决定是否重新提交。

## 搜索与连接边界

```python
from yunlink_python import discover

for bridge in discover(timeout=1.0):
    print(bridge.endpoint_uid, bridge.ip, bridge.tcp_port, bridge.profiles)
    for entity in bridge.entities:
        print(entity.entity_uid, entity.kind, entity.attributes)
```

搜索返回 Bridge 的 `endpoint_uid`、Profiles、Entities 和设备属性。`connect()` 只建立
Bridge Session；`client.entities()` 读取目录；`client.vehicle(entity_uid)` 或
`client.entity(entity_uid)` 才会 attach 具体设备。

`discover_and_connect()` 仍然可用，但只建议在确认网络中只有一个 Bridge 时使用。它不应作为多机网络的
默认入口，因为它不会替用户决定要控制哪一个设备。

完整的中文教程和按步骤编号的可运行脚本见 [`examples`](examples)：搜索连接、实体查看、状态订阅、UAV 基础移动、多航点规划、Action 取消、UGV 控制和异常处理。
局域网存在多个 Bridge 或多台 UAV 时，使用 [`examples/10_discover_select_connect.py`](examples/10_discover_select_connect.py)：先按 `endpoint_uid` 选择 Bridge，再按 `entity_uid` 选择具体 UAV/UGV。
该脚本会把全部搜索结果完整打印出来，再按稳定的 Bridge ID 和设备 ID 连接；不会默认连接搜索结果中的第一台设备。

一个 Client 可以创建多个独立的 `Vehicle`/`Ugv` 对象。需要并行控制时由应用自己的线程或任务编排，
参见 [`examples/11_multi_device_control.py`](examples/11_multi_device_control.py)、
[`examples/12_multi_uav_waypoints.py`](examples/12_multi_uav_waypoints.py) 和
[`examples/13_multi_device_state.py`](examples/13_multi_device_state.py)。SDK 不自动编队、不自动重放飞行动作，
`endpoint_uid` 和 `entity_uid` 仍然是两级不同的选择 ID。
测试人员可直接参考 [`TESTER_GUIDE.md`](TESTER_GUIDE.md)，其中包含安装、执行顺序和结果记录模板。

## MATLAB

MATLAB 包装位于 [`matlab`](matlab)，内部只调用 MATLAB Python Interface，不实现 Wire 或 MEX。

```matlab
client = yunlink_connect("192.168.31.236:9696");
uav = yunlink_vehicle(client, "uav1");

yunlink_takeoff(uav, 1.5);
yunlink_move_to(uav, 2.0, 0.0, 1.5);
state = yunlink_state(uav);
yunlink_land(uav);

yunlink_close(client);
```

MATLAB 必须配置到已经安装 `yunlink-python` 的 Python 3.10 至 3.12 环境。
完整的安装、更新、Toolbox 打包和状态字段说明见 [`matlab/README.md`](matlab/README.md)。

## API 边界

SDK 提供 UAV 的起飞、MoveTo、航点、直接位置/速度控制、悬停、返航、取消、降落和明确确认的紧急上锁，也提供现有协议
支持范围内的 UGV 实体、点位、速度和 Hold。它不包含相机、云台、点云、编队或任务编排，
也不连接 ROS。高级用户可通过 `client.raw` 访问通用 YunLink Transport；普通脚本不需要
理解 Wire、Session、TypeRef 或 Protobuf。

兼容版本见 [COMPATIBILITY.md](COMPATIBILITY.md)。

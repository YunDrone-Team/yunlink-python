# yunlink-sunray

`yunlink-sunray` 是面向 SunrayV2 的简洁 Python 控制 SDK。它通过 YunLink Bridge
连接无人机，不依赖 ROS，也不替代 Bridge。

```text
Python / MATLAB
      |
yunlink-sunray       Sunray 便捷接口
      |
yunlink              通用 YunLink Wire v2 Python 绑定
      |
YunLink ROS Bridge   ROS 与 YunLink 的边界
      |
SunrayV2
```

## 安装

当前首个 GitHub Release 为 `v1.0.0`。由于 `yunlink` 依赖包含平台相关的原生运行库，
请先安装与系统和 Python 版本匹配的 YunLink wheel，再安装本仓库的
`yunlink-sunray` wheel。两个包目前都不发布到 PyPI。

SDK wheel 和源码包可从 [GitHub Releases](https://github.com/YunDrone-Team/yunlink-python/releases/tag/v1.0.0)
下载。

开发环境可以从源码安装：

```bash
git clone --recursive https://github.com/YunDrone-Team/yunlink.git
python -m pip install ./yunlink/bindings/python

git clone https://github.com/YunDrone-Team/yunlink-python.git
python -m pip install ./yunlink-python
```

支持 Python 3.10、3.11 和 3.12。

## 第一个飞行脚本

以下动作会真实发送控制命令。请先确认连接的是仿真实体，并确保飞行区域安全。

```python
from yunlink_sunray import discover_and_connect

with discover_and_connect() as client:
    vehicle = client.vehicle()
    vehicle.takeoff(height_m=1.5, timeout=30)
    vehicle.move_to(x=2.0, y=0.0, z=1.5, timeout=60)
    vehicle.land(timeout=30)
```

已知 Bridge 地址时不需要搜索：

```python
from yunlink_sunray import connect

with connect("192.168.31.236:9696") as client:
    # The display name (uav1) and the opaque entity UID are both accepted.
    vehicle = client.vehicle("uav1")
    vehicle.takeoff(1.5)
    vehicle.move_to(2.0, 0.0, 1.5)
    vehicle.land()
```

## 航点和状态

```python
from yunlink_sunray import Waypoint, connect

with connect("192.168.31.236:9696") as client:
    vehicle = client.vehicle("uav1")

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

## 搜索

```python
from yunlink_sunray import discover

for bridge in discover(timeout=1.0):
    print(bridge.endpoint_uid, bridge.ip, bridge.tcp_port, bridge.profiles)
    for entity in bridge.entities:
        print(entity.entity_uid, entity.kind, entity.attributes)
```

搜索返回 Bridge 的 endpoint、Profiles、Entities 和设备属性（例如运行模式）。网络不允许广播时，直接使用
`connect("host:9696")`。

完整的中文教程和按步骤编号的可运行脚本见 [`examples`](examples)：搜索连接、实体查看、状态订阅、UAV 基础移动、多航点规划、Action 取消、UGV 控制和异常处理。
局域网存在多个 Bridge 或多台 UAV 时，使用 [`examples/10_discover_select_connect.py`](examples/10_discover_select_connect.py)：先按 `endpoint_uid` 选择 Bridge，再按 `entity_uid` 选择具体 UAV/UGV。
多 Bridge 场景请使用 [`examples/10_discover_select_connect.py`](examples/10_discover_select_connect.py)，按搜索结果中的 `endpoint_uid` 选择目标。
该脚本会把全部搜索结果完整打印出来，再按 ID 或序号连接；不会默认连接搜索结果中的第一台设备。

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

MATLAB 必须配置到已经安装 `yunlink-sunray` 的 Python 3.10 至 3.12 环境。

## API 边界

SDK 提供 UAV 的起飞、MoveTo、航点、悬停、取消、降落和基础速度控制，也提供现有协议
支持范围内的 UGV 实体、点位、速度和 Hold。它不包含相机、云台、点云、编队或任务编排，
也不连接 ROS。高级用户可通过 `client.raw` 访问通用 YunLink Transport；普通脚本不需要
理解 Wire、Session、TypeRef 或 Protobuf。

兼容版本见 [COMPATIBILITY.md](COMPATIBILITY.md)。

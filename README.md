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

## 获取方式

Python 从本仓库安装。MATLAB 从本仓库的 GitHub Release 下载用户包，不必克隆源码。

## 环境要求

Python **必须是 3.10、3.11、3.12 或 3.13**。底层通信库 [yunlink](https://github.com/YunDrone-Team/yunlink) 要求 CPython ≥ 3.10（依赖 `protobuf>=7`，该系列同样只要 3.10+），因此 3.8/3.9 无法使用。

MATLAB 用户请用 **R2022b 或更新**。R2022a 官方只支持 Python 3.8/3.9，和 yunlink 的 3.10 底线没有交集，会出现「Python 命令需要支持的 CPython 版本」。R2022b 请安装 Python 3.10。

## 安装

当前 SDK 版本为 `1.3.0`。两个包目前都不在 PyPI。`yunlink` 含平台原生库，请先装
[yunlink v2.0.2](https://github.com/YunDrone-Team/yunlink/releases/tag/v2.0.2)
里匹配本机的预编译 wheel，不必编译 C++。

按文件名选择：`cp310`/`cp311`/`cp312`/`cp313` 对应 Python 3.10 到 3.13；
`macosx_*_arm64`、`macosx_*_x86_64`、`manylinux_*_x86_64`、`manylinux_*_aarch64`、
`win_amd64` 对应系统和架构。

```bash
python -m pip install \
  https://github.com/YunDrone-Team/yunlink/releases/download/v2.0.2/yunlink-2.0.1-cp313-cp313-macosx_11_0_arm64.whl

git clone https://github.com/YunDrone-Team/yunlink-python.git
cd yunlink-python
python -m pip install --no-deps -e .
```

`--no-deps` 必须加，否则 pip 会去 PyPI 找不存在的 `yunlink`。不要使用 `uv run`，
它同样会从包索引解析依赖。激活虚拟环境后，先复制 `examples/yunlink.env.example` 为 `examples/yunlink.env` 并填写目标，
再运行 `python examples/01_discover.py`。不要每次 export 环境变量。

支持 Python 3.10、3.11、3.12 和 3.13。不要用 3.8/3.9。

完整中文使用手册见 [`docs/USAGE_GUIDE_CN.md`](docs/USAGE_GUIDE_CN.md)，公开方法对照见
[`docs/API_CN.md`](docs/API_CN.md)，文档索引见 [`docs/README.md`](docs/README.md)。

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

搜索全部 Bridge。地面站探测列表用 `endpoint_uid@ip:tcp_port` 区分一台可连接的 Bridge，
设备再用 `endpoint_uid::entity_uid` 路由：

```python
from yunlink_python import discover, discovery_id, print_discovered_bridges, vehicle_key

bridges = discover(timeout=5)
print_discovered_bridges(bridges)

bridge = bridges[0]
print(discovery_id(bridge.endpoint_uid, bridge.ip, bridge.tcp_port))
print(vehicle_key(bridge.endpoint_uid, bridge.entities[0].entity_uid))
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

`discover()` 返回 Bridge 广告，其中稳定选择键是 `endpoint_uid`，地面站探测候选 ID 是
`endpoint_uid@ip:tcp_port`。`connect()` 只建立 Bridge Session；`client.entities()`
读取目录；`client.vehicle(entity_uid)` 或 `client.entity(entity_uid)` 才会 attach 具体设备。

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

MATLAB 用户从 GitHub Release 下载打包好的 Toolbox，不必克隆本仓库：

https://github.com/YunDrone-Team/yunlink-python/releases/download/matlab-1.4.5/yunlink-sunray-matlab-1.4.5-bundle.zip

请先安装 `.mltbx`，运行 `yunlink_examples` 与 `ex00_setup`，再按编号跑 example。熟悉之后查阅 [`matlab/developer/API.md`](matlab/developer/API.md)。逐步说明书的 Typst 源码在 [`matlab/docs`](matlab/docs/README.md)，可自行编译 PDF；Release 同时提供 `yunlink-matlab-manual.pdf`。

本仓库的 Release 仅提供该 MATLAB 用户包。安装和使用见 [`matlab/README.md`](matlab/README.md)。开发者打包见
[`matlab/developer/README.md`](matlab/developer/README.md)。

## API 边界

SDK 提供 UAV 的起飞、MoveTo、航点、直接位置/速度控制、悬停、返航、取消、降落和明确确认的紧急上锁，也提供现有协议
支持范围内的 UGV 实体、点位、速度和 Hold。它不包含相机、云台、点云、编队或任务编排，
也不连接 ROS。高级用户可通过 `client.raw` 访问通用 YunLink Transport；普通脚本不需要
理解 Wire、Session、TypeRef 或 Protobuf。

兼容版本见 [COMPATIBILITY.md](COMPATIBILITY.md)。

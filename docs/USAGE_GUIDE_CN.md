# YunLink Python 完整中文使用手册

## 1. SDK 能做什么

`yunlink-python` 是面向 SunrayV2 的 Python 控制 SDK。它通过 YunLink Bridge 提供：

- Bridge 搜索和连接。
- UAV/UGV 设备目录读取。
- UAV 状态读取、起飞、移动、悬停、航点、取消和降落。
- UGV 状态读取、MovePoint、速度租约和 Hold。
- 同步 Action、非阻塞 `ActionHandle`、超时和断线错误传播。

SDK 不连接 ROS，不复制 ROS 服务，不自动选择第一台设备，也不会在断线后自动重放飞行动作。

## 2. 运行前准备

开始前确认：

1. YunLink Bridge 已启动并监听 TCP 端口，默认端口是 `9696`。
2. 仿真或真实设备已经注册到 Bridge 的设备目录。
3. Python 版本为 3.10、3.11 或 3.12。
4. 第一次测试优先使用仿真实体，真实设备必须遵守现场安全规定。

控制脚本会发送真实动作。只读搜索、目录查看和状态查看不会起飞或移动设备。

## 3. Bridge、设备和两级 ID

SDK 有两个不能混用的 ID：

| ID | 含义 | 用途 |
| --- | --- | --- |
| `endpoint_uid` | YunLink Bridge 的唯一 ID | 在多 Bridge 局域网中选择 Bridge |
| `entity_uid` | Bridge 下 UAV/UGV 的唯一 ID | attach、读取状态和发送设备动作 |

IP 地址只是连接地址，不是设备 ID。显示名称例如 `uav1` 可以用于选择，但多设备场景应优先记录并使用完整的 `entity_uid`。

连接层次如下：

```text
搜索 Bridge
  -> 选择 endpoint_uid
  -> 建立 Bridge Session
  -> client.entities() 读取设备目录
  -> 选择 entity_uid
  -> client.vehicle(uid) / client.ugv(uid) attach 设备
  -> 读取状态
  -> Action 申请所需权限并发送控制
```

`connect()` 只连接 Bridge，不会自动连接 UAV。`client.entities()` 只读取目录，不会 attach。
只有 `client.vehicle(uid)`、`client.ugv(uid)` 或 `client.entity(uid)` 才会 attach 设备并建立状态订阅。

## 4. 安装 YunLink binding 与 SDK

YunLink binding 包含平台相关运行库，需要先安装与操作系统匹配的 wheel：

```bash
# 先安装通用 YunLink Python binding。
python -m pip install /path/to/yunlink-*.whl

# 再安装本 SDK 的 wheel。
python -m pip install /path/to/yunlink_python-1.0.0-py3-none-any.whl

# 确认 Python import 名称和版本。
python -c "import yunlink_python; print(yunlink_python.__version__)"
```

开发环境也可以从源码安装：

```bash
git clone --recursive https://github.com/YunDrone-Team/yunlink.git
python -m pip install ./yunlink/bindings/python

git clone https://github.com/YunDrone-Team/yunlink-python.git
cd yunlink-python
python -m pip install -e .
```

## 5. 第一步：搜索全部 Bridge

先运行：

```bash
python examples/01_discover.py
```

这个脚本只发送 discovery 查询，不建立控制 Session，不 attach 设备，不发送动作。
输出中重点记录每个 Bridge 的 `endpoint_uid` 和地址：

```text
Bridge ID: bridge-abc
Address: 192.168.31.236:9696
  Device ID: uav-abc-01 (sunray.uav)
```

如果没有搜索结果：

- 检查 Bridge 是否启动。
- 检查 UDP discovery 端口和局域网广播权限。
- 已知地址时跳过广播，直接使用 `--address` 或 `connect("host:9696")`。

## 6. 第二步：连接指定 Bridge

如果只有一个 Bridge，可以运行：

```bash
python examples/02_connect_and_inspect.py --address 192.168.31.236:9696
```

不传 `--address` 时，脚本会尝试发现唯一 Bridge。如果发现多个 Bridge，会要求先使用示例 10 按 `endpoint_uid` 选择。

脚本执行到这里只完成：

```text
TCP 连接 -> YunLink Session -> Profile 协商
```

此时还没有 attach UAV，也没有申请飞控权限。

## 7. 第三步：打印完整设备目录

`02_connect_and_inspect.py` 会调用：

```python
with connect("192.168.31.236:9696") as client:
    # 这一步读取 Bridge 的实时目录，不会 attach 任何设备。
    devices = client.entities()
    for device in devices:
        print(f"entity_uid={device.uid}")
        print(f"name={device.name} kind={device.kind}")
        print(f"attributes={device.attributes}")
        print(f"capabilities={device.capabilities}")
```

请记录目标设备的 `entity_uid`。不要把上层 Bridge 的 `endpoint_uid` 填到 `client.vehicle()`。

## 8. 第四步：按 `entity_uid` attach 设备

使用目录中确认过的设备 ID：

```bash
python examples/03_watch_state.py \
  --address 192.168.31.236:9696 \
  --entity <entity_uid> \
  --seconds 10
```

对应的 Python 代码：

```python
from yunlink_python import connect

with connect("192.168.31.236:9696") as client:
    # 连接 Bridge 后先查看目录，避免把错误设备当成目标。
    for device in client.entities():
        print(device.uid, device.name, device.kind)

    # 这里传入明确的 entity_uid 或设备名称。
    # 调用 vehicle() 后 SDK 才会 attach UAV 并订阅状态。
    uav = client.vehicle("<entity_uid>")
    print(uav.state)
```

多台 UAV 同时存在时省略 ID 会失败，SDK 不会默认选择第一台 UAV。

## 9. 第五步：读取 UAV/UGV 状态

状态对象是最近一次收到的不可变快照：

```python
state = uav.state
print("connected:", state.connected)
print("fresh:", state.is_fresh())
print("position:", state.position)
print("velocity:", state.velocity)
print("landed:", state.landed)
print("battery:", state.battery_percent)
print("planner:", state.planner)
```

持续监听状态：

```python
def show_state(state) -> None:
    # 回调只负责观察状态，不应在这里重复提交控制动作。
    print(state.position, state.battery_percent, state.planner)

unsubscribe = uav.on_state_changed(show_state)
try:
    # 这里执行你的只读业务逻辑。
    pass
finally:
    # 结束程序前取消回调，避免继续向已关闭的业务对象投递状态。
    unsubscribe()
```

## 10. 第六步：起飞、移动、悬停和降落

确认状态新鲜、目标设备正确且现场安全后，才运行控制示例：

```bash
python examples/04_flight_basics.py \
  --address 192.168.31.236:9696 \
  --entity <entity_uid>
```

最小控制代码：

```python
from yunlink_python import connect

with connect("192.168.31.236:9696") as client:
    # 先使用已确认的设备 ID attach UAV。
    uav = client.vehicle("<entity_uid>")
    try:
        # 从这一行开始会发送真实控制命令。
        uav.takeoff(height_m=1.0, timeout=30)
        start = uav.state.position
        uav.move_to(start.x + 0.3, start.y, 1.0, timeout=60)
        uav.hover(timeout=15)
    finally:
        # 这是尽力清理，不代表断线或硬件故障时一定能够降落成功。
        if not uav.state.landed:
            uav.land(timeout=30)
```

## 11. 第七步：航点任务

```bash
python examples/05_waypoints.py \
  --address 192.168.31.236:9696 \
  --entity <entity_uid>
```

航点任务会等待 Planner Action 的最终结果，并从状态中显示当前航点、距离、停留时间和失败原因。
它不是只发布坐标；任务失败、超时或权限拒绝都会以 SDK 异常或 Action 结果暴露。

## 12. 第八步：异步 Action 与取消

```bash
python examples/06_cancel_action.py \
  --address 192.168.31.236:9696 \
  --entity <entity_uid> \
  --after 2
```

非阻塞调用返回 `ActionHandle`：

```python
handle = uav.takeoff(1.0, wait=False)
print(handle.action_id, handle.phase, handle.progress)

# cancel() 只取消这个 Action；Planner cancel 可用于停止当前实体任务。
handle.cancel()
result = handle.wait(timeout=15)
print(result.phase, result.detail)
```

断线时未完成 Action 会变为 `DisconnectedError`，SDK 不会自动重放起飞、移动、航点或降落。

## 13. 第九步：多 Bridge 和多设备

多 Bridge 场景：

```bash
python examples/10_discover_select_connect.py
```

自动化调用必须显式提供 Bridge ID：

```bash
python examples/10_discover_select_connect.py \
  --id <endpoint_uid> \
  --entity <entity_uid>
```

该脚本先搜索全部 Bridge，再按 `endpoint_uid` 连接指定 Bridge，连接后打印实时设备目录，最后才按 `entity_uid` attach 设备。

多设备示例会明确遍历目录中每个实体，适合验证独立控制，不代表编队或集群控制：

```bash
python examples/11_multi_device_control.py
python examples/12_multi_uav_waypoints.py
python examples/13_multi_device_state.py --seconds 60
```

## 14. 第十步：错误、超时和断线恢复

```bash
python examples/08_errors.py --address 192.168.31.236:9696 --entity <entity_uid>
```

常见异常：

| 异常 | 含义 |
| --- | --- |
| `ConnectionError` | Bridge 不可达、Profile 不兼容或连接协商失败 |
| `EntityNotFoundError` | 设备 ID/名称不存在或不明确 |
| `AuthorityError` | 申请控制权限被拒绝 |
| `ActionFailedError` | Bridge 或设备拒绝/执行失败 |
| `TimeoutError` | 在指定时间内没有得到结果 |
| `DisconnectedError` | Session 断线，未完成动作不会自动重放 |

遇到错误时先记录 Bridge 地址、Bridge ID、设备 ID、SDK 版本、Action 阶段和 Bridge 日志，不要盲目重复提交飞行动作。

## 15. 真实设备使用注意事项

- 首次运行先使用 `01`、`02`、`03` 做只读搜索、目录和状态验证。
- 控制前确认 `entity_uid`、设备位置、飞行区域和安全人员状态。
- 仿真与真实设备使用同一套 SDK API，但仿真通过不等于真实飞控验收完成。
- 断线恢复只恢复 Session、attach、权限和状态订阅，不恢复飞行动作。
- `finally` 中的降落是尽力清理，不能替代现场安全员和硬件急停方案。
- 不要在真实设备上把默认设备名或列表序号当作稳定目标。

## 16. API 快速索引

| API | 作用 | 是否 attach |
| --- | --- | --- |
| `discover()` | 搜索 Bridge | 否 |
| `connect(address)` | 连接 Bridge | 否 |
| `connect_discovered(bridge)` | 连接已选 Bridge | 否 |
| `client.bridge_uid` | 获取远端 Bridge ID | 否 |
| `client.entities()` | 读取设备目录 | 否 |
| `client.vehicle(uid)` | attach UAV 并订阅状态 | 是 |
| `client.ugv(uid)` | attach UGV 并订阅状态 | 是 |
| `client.entity(uid)` | 按类型 attach 设备 | 是 |
| `vehicle.takeoff()` | 起飞 Action | 已 attach 后申请权限 |
| `vehicle.move_to()` | Planner 单目标移动 | 已 attach 后申请权限 |
| `vehicle.waypoints()` | Planner 航点任务 | 已 attach 后申请权限 |
| `vehicle.cancel()` | 取消当前实体任务 | 已 attach 后申请权限 |
| `vehicle.land()` | 降落 Action | 已 attach 后申请权限 |

## 17. 常见问题排查

### 搜索不到 Bridge

确认 Bridge 已运行、UDP discovery 端口可达。已知 TCP 地址时直接使用 `--address`，不依赖广播。

### 连接成功但没有设备

连接的是 Bridge，不代表 Bridge 已发现 SunrayV2 实体。检查 Bridge 目录、设备进程和实体注册日志。

### 设备 ID 不存在

重新运行 `02_connect_and_inspect.py` 获取实时 `entity_uid`。不要凭记忆填写 IP、列表序号或另一台 Bridge 的设备 ID。

### 状态不新鲜

确认设备已经 attach、Bridge 正在发布对应 Stream，并检查网络和设备端状态源。

### 动作权限被拒绝

确认目标实体仍在线、当前 Session 已 attach，且没有其他控制端持有冲突权限。

### 断线后动作没有继续

这是 SDK 的安全语义。未完成动作不会自动重放，必须由程序重新读取状态并明确决定是否重新提交。

## 18. 从仿真迁移到真实设备

代码通常只需要替换 Bridge 地址和显式 `entity_uid`：

```python
with connect("真实 Bridge 地址:9696") as client:
    # 先打印真实目录，确认设备 ID 后再替换下面的值。
    for device in client.entities():
        print(device.uid, device.name, device.kind)
    uav = client.vehicle("真实设备 entity_uid")
```

不要把仿真的 `uav1`、仿真 IP 或仿真状态假设带入真实设备。先完成只读目录和状态检查，再在现场安全流程允许的情况下执行控制。

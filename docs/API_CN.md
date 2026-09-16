# YunLink Python / MATLAB API

源码在本仓库。本页列出对外封装，不讲 Wire 协议细节。底层会话与 Profile 见 [yunlink](https://github.com/YunDrone-Team/yunlink)。使用步骤见 [USAGE_GUIDE_CN.md](USAGE_GUIDE_CN.md)。

MATLAB 函数是对 Python SDK 的薄封装。行为以 Python 为准。

## 连接边界

| 步骤 | Python | MATLAB | 会不会控制设备 |
| --- | --- | --- | --- |
| 搜索 Bridge | `discover(timeout=5)` | `yunlink_discover(timeout)` | 否 |
| 连接 Bridge | `connect("ip:9696")` | `yunlink_connect(address)` | 否 |
| 看目录 | `client.entities()` | `yunlink_entities(client)` | 否 |
| attach UAV | `client.vehicle(uid)` | `yunlink_vehicle(client, uid)` | 只订阅状态 |
| attach UGV | `client.ugv(uid)` | `yunlink_ugv(client, uid)` | 只订阅状态 |
| 关闭 | `client.close()` | `yunlink_close(client)` | 释放 Session |

`endpoint_uid` 是 Bridge。`entity_uid` 是设备。探测列表用 `endpoint_uid@ip:tcp_port`。不要用 IP 当设备 ID。

```python
from yunlink_python import connect, discover

bridges = discover(timeout=5)
with connect("192.168.10.10:9696") as client:
    for item in client.entities():
        print(item.uid, item.name, item.kind)
    uav = client.vehicle("e-89c423-2-1")
    ugv = client.ugv("e-89c423-3-1")
```

## 模块入口 `yunlink_python`

| 名称 | 作用 |
| --- | --- |
| `discover` | 搜索局域网 Bridge |
| `connect` | 按 `host:port` 建立 Session |
| `connect_discovered` | 按已搜索到的 Advertisement 连接 |
| `discover_and_connect` | 搜索到唯一 Bridge 时直接连接 |
| `discovery_id` | `endpoint_uid@ip:tcp_port` |
| `vehicle_key` | `endpoint_uid::entity_uid` |
| `print_discovered_bridges` / `print_client_catalog` / `print_entity_catalog` | 终端表格 |
| `run_with_status` | 示例用状态行 |
| `Waypoint` | 航点 `x, y, z, yaw_rad, hold_time_s` |

## Client

| 方法 / 属性 | 说明 |
| --- | --- |
| `bridge_uid` | 远端 `endpoint_uid` |
| `bridge_address` | `host:port` |
| `entities()` | 实时目录，不 attach |
| `vehicles()` / `ugvs()` | 按 kind 过滤 |
| `vehicle(uid)` / `ugv(uid)` | attach；多机必须传 uid |
| `entity(uid)` | 按 uid 或名称选 UAV/UGV |
| `close()` | 关闭 Session |
| `raw` | 底层 Transport，一般不要用 |

`EntityInfo`：`uid`、`name`、`kind`、`attributes`、`capabilities`。

## Vehicle（会飞）

默认 `wait=True`，返回 `ActionResult`。`wait=False` 返回 `ActionHandle`。

| Python | MATLAB | 默认超时 | 说明 |
| --- | --- | --- | --- |
| `state` | `yunlink_state` / `yunlink_state_raw` | — | 只读 |
| `on_state_changed(cb)` | `yunlink_monitor` | — | 订阅/轮询 |
| `is_state_fresh()` | `state.fresh` | — | 过期不要起飞 |
| `takeoff(height_m=1.5)` | `yunlink_takeoff(v, h, t)` | 30 s | 已在空中可能被 INIT 拒绝 |
| `hover()` | `yunlink_hover` | 15 s | |
| `land()` | `yunlink_land` | 30 s | |
| `return_home()` | `yunlink_return_home` | 120 s | |
| `emergency_lock(confirm=True)` | `yunlink_emergency_lock(v, true)` | 20 s | MATLAB 必须显式 true |
| `position_control(x,y,z,yaw_rad=0)` | `yunlink_position_control` | 120 s | 不走 Planner |
| `velocity(vx,vy,vz=0)` | `yunlink_velocity_control` | 15 s | 租约结束常见 CANCELLED |
| `forward/backward/left/right/up/down` | `yunlink_translate` | 15 s | 机体轴短时平移 |
| `move_to(x,y,z)` | `yunlink_move_to` | 60 s | Planner 单目标，等到达 |
| `waypoint` / `waypoints` | `yunlink_waypoint` / `yunlink_waypoints` | 120 s | |
| `cancel()` | `yunlink_cancel` | 15 s | 取消当前动作或 Planner |
| `command(kind, **kw)` | `yunlink_command` | 视 kind | takeoff/position/velocity/hover/return_home/land/emergency_lock |

`VehicleState` 常用字段：`connected`、`fresh`、`position`、`velocity`、`attitude`、`armed`、`landed`、`battery_percent`、`px4_mode`、`control_mode_name`、`movement_mode`、`localization`、`planner`。MATLAB 结构体用 camelCase（`batteryPercent`、`movementMode`）。

## Ugv（会走）

| Python | MATLAB | 默认超时 | 说明 |
| --- | --- | --- | --- |
| `state` | `yunlink_ugv_state` | — | 只读；`frame_id` 空时不要 MovePoint |
| `move_to(x, y)` | `yunlink_ugv_move_to` | 60 s | 平面点位 |
| `velocity(vx, vy=0)` | `yunlink_ugv_velocity` | 15 s | 短时租约 |
| `hold()` | `yunlink_ugv_hold` | 15 s | |
| `cancel()` | `yunlink_cancel` 同类 | 15 s | |

## 动作结果与异常

`ActionResult`：`action_id`、`phase`、`result_code`、`detail`。`ActionHandle`：`done`、`progress`、`wait()`、`cancel()`。

速度类动作租约到期经常是 `CANCELLED`，表示控制状态确认结束，不一定是失败。

| 异常 | 含义 |
| --- | --- |
| `ConnectionError` | 未连上、无坐标系、Session 问题 |
| `TimeoutError` | 动作或协商超时 |
| `EntityNotFoundError` | uid/名称对不上 |
| `AuthorityError` | 控制权被其他 Session 占用 |
| `ActionFailedError` | 飞控/Planner 拒绝 |
| `DisconnectedError` | 连接已断开 |

MATLAB 里这些以 `Python Error: ...` 抛出。不要 `disp` Python 动作对象，`-batch` 下可能卡住。

## MATLAB 仅有的辅助函数

| 函数 | 作用 |
| --- | --- |
| `yunlink_setup` | 指定 Python 3.10–3.13，解压 bundle 里的 wheel（不走 pip） |
| `yunlink_update` | 同 setup |
| `yunlink_prepare_runtime` | 设置 `KMP_DUPLICATE_LIB_OK`，避免 OpenMP 冲突 |
| `yunlink_examples` | 打开示例目录 |
| `yunlink_monitor` | 按周期采样 UAV 状态 |

Windows 上 `yunlink_setup` 只选 `win_amd64`（64 位 MATLAB），不会把 `win32` 当成同一包。

## 环境

- Python 3.10–3.13：底层 [yunlink](https://github.com/YunDrone-Team/yunlink) 要求 ≥ 3.10
- MATLAB R2022b 或更新，且解释器必须是该 MATLAB 官方支持的 CPython
- 绑定包 `yunlink` 2.0.1，SDK `yunlink_python` 1.3.x
- Bridge 协商 `org.yunlink.mobility@1` 与 `com.yundrone.sunray@2`

MATLAB 每个函数的参数与示例见 [`matlab/developer/API.md`](../matlab/developer/API.md)。

浙江万里学院出厂固件用分支 `浙江万里学院适配` 和 Release `matlab-wanli`，不要和本页 main 包混用。

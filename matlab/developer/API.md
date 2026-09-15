# MATLAB 封装函数

用户安装见 [../README.md](../README.md)。Python 对照见 [../../docs/API_CN.md](../../docs/API_CN.md)。行为以 Python SDK 为准，这里只写 MATLAB 怎么调。

命令窗口里函数名不要带 `.m`：写 `ex01_discover`，不要写 `ex01_discover.m`。

最低环境：**MATLAB R2022b**，**CPython 3.10–3.13**（须为该 MATLAB 官方支持的版本）。yunlink 绑定要求 Python ≥ 3.10。

## 推荐顺序

```matlab
yunlink_examples                    % 打开示例目录
% 编辑并运行 ex00_setup
bridges = yunlink_discover(5)
client  = yunlink_connect("192.168.10.10:9696")
infos   = yunlink_entities(client)
uav     = yunlink_vehicle(client, "e-89c423-2-1")
ugv     = yunlink_ugv(client, "e-89c423-3-1")
pause(0.5)
us = yunlink_state(uav)             % us.fresh 为 true 再飞
gs = yunlink_ugv_state(ugv)
yunlink_close(client)
```

`connect` 不等于 attach。没传 `entity_uid` 之前不会控制任何飞机。

## 安装与运行时

### `yunlink_setup`

```matlab
yunlink_setup                       % 桌面向导
yunlink_setup(pythonExe, bundleDir) % 推荐：ex00_setup 走这条
yunlink_setup(pythonExe, sdkWhl, bindingWhl)
```

把 bundle 里的 `yunlink` / `yunlink_python` wheel 解压进该 Python，并记下路径供下次启动。不走 pip。64 位 Windows 只选 `win_amd64`。

### `yunlink_update`

同 `yunlink_setup`。

### `yunlink_prepare_runtime` / `yunlink_ensure_python`

各控制函数会间接调用。恢复上次 Python、设置 `KMP_DUPLICATE_LIB_OK`、检查本 MATLAB 能否调用该 CPython。一般不必手写。

### `yunlink_examples`

把当前文件夹切到 Toolbox 的 `examples/`。

## 连接

### `yunlink_discover`

```matlab
bridges = yunlink_discover          % 默认听 5 秒
bridges = yunlink_discover(3)
```

不连接、不飞。返回结构体数组：`endpointUid`、`ip`、`tcpPort`、`address`、`discoveryId`（`endpoint_uid@ip:port`）、`name`、`entities`。

### `yunlink_connect` / `yunlink_close`

```matlab
client = yunlink_connect("192.168.10.10:9696")
cleaner = onCleanup(@() yunlink_close(client));
```

只建 Bridge Session。

### `yunlink_entities`

```matlab
infos = yunlink_entities(client)
% infos(i).uid / .name / .kind
```

### `yunlink_vehicle` / `yunlink_ugv`

```matlab
uav = yunlink_vehicle(client, "e-89c423-2-1")
ugv = yunlink_ugv(client, "e-89c423-3-1")
```

多机必须传完整 `entity_uid`。这一步才订阅遥测。

## UAV 状态

### `yunlink_state`

MATLAB 结构体，字段 camelCase。常用：`fresh`、`connected`、`landed`、`armed`、`position.x/y/z`、`batteryPercent`、`px4Mode`、`movementMode`、`frameId`、`planner`。`fresh` 为 false 时不要起飞。

### `yunlink_state_raw`

底层 Python `VehicleState`，一般不用。

### `yunlink_monitor`

```matlab
hist = yunlink_monitor(uav, 10)                          % 默认 0.2 s 打印
hist = yunlink_monitor(uav, 10, struct('print', false, 'period_s', 0.5))
```

只采样，不发送控制。

## UAV 控制（会飞）

返回值是 Python `ActionResult`。不要 `disp(result)`，`-batch` 下可能卡住。用 `string(result.detail)` 即可。

| 函数 | 调用 | 默认超时 |
| --- | --- | --- |
| `yunlink_takeoff` | `yunlink_takeoff(uav, 1.0)` 或第三参 timeout | 30 s |
| `yunlink_hover` | `yunlink_hover(uav)` | 15 s |
| `yunlink_land` | `yunlink_land(uav)` | 30 s |
| `yunlink_return_home` | `yunlink_return_home(uav)` | 120 s |
| `yunlink_emergency_lock` | `yunlink_emergency_lock(uav, true)` 第二参必须为 true | 20 s |
| `yunlink_move_to` | `yunlink_move_to(uav, x, y, z)` | 60 s |
| `yunlink_waypoint` | `yunlink_waypoint(uav, x, y, z)` | 120 s |
| `yunlink_waypoints` | `yunlink_waypoints(uav, [x1 y1 z1; x2 y2 z2])` | 120 s |
| `yunlink_position_control` | `yunlink_position_control(uav, x, y, z, yaw_rad)` | 120 s |
| `yunlink_translate` | `yunlink_translate(uav, "forward")`；方向 `forward/backward/left/right/up/down` | 15 s |
| `yunlink_cancel` | `yunlink_cancel(uav)` | 15 s |

速度：

```matlab
opts = struct('duration_s', 1.0, 'lease_ms', 1000, 'timeout', 15);
yunlink_velocity_control(uav, 0.2, 0, 0, opts)
```

`options` 还可含 `wait`、`frame_id`、`height_lock_m`。租约到期常为 `CANCELLED`，不是失败。

已在空中时 `takeoff` 可能被 INIT 拒绝，先 `yunlink_land`。

### `yunlink_command`

```matlab
yunlink_command(uav, "takeoff", struct('height_m', 1.0))
yunlink_command(uav, "land")
```

`kind`：`takeoff` / `position` / `velocity` / `hover` / `return_home` / `land` / `emergency_lock`。

## UGV 控制（会走）

`frame_id` 为空时不要 `move_to`，等 `yunlink_ugv_state` 新鲜。

```matlab
s = yunlink_ugv_state(ugv)          % .fresh .position .velocity .controlState
yunlink_ugv_move_to(ugv, s.position.x + 0.3, s.position.y)   % 默认 60 s
yunlink_ugv_velocity(ugv, 0.1, 0)                            % 短时租约
yunlink_ugv_hold(ugv)
```

## 最小飞行例

```matlab
client = yunlink_connect("192.168.10.10:9696");
cleaner = onCleanup(@() yunlink_close(client));
uav = yunlink_vehicle(client, "e-89c423-2-1");
pause(0.6)
s = yunlink_state(uav);
assert(s.fresh, '遥测不新鲜')
if ~s.landed
    yunlink_land(uav, 30)
end
yunlink_takeoff(uav, 1.0, 30)
yunlink_hover(uav, 8)
yunlink_land(uav, 30)
```

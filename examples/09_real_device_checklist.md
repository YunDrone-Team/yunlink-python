# 真实设备运行检查清单

SDK 的控制接口不区分仿真和真实设备。Python 端只看到 YunLink Bridge 暴露的实体、Profile、状态流和 Action：

```text
Python SDK -> YunLink Session -> Attach/Authority -> Bridge -> SunrayV2 -> 控制器/设备
```

真实设备使用同一套代码：

```python
from yunlink_python import connect

with connect("真实 Bridge 的地址:9696") as client:
    uav = client.vehicle("目录中的 UAV 名称或 entity UID")
    print(uav.state)
    uav.takeoff(1.5, timeout=30)
    uav.move_to(1.0, 0.0, 1.5, timeout=60)
    uav.hover()
    uav.land(timeout=30)
```

## 接入前检查

1. 真实设备上的 SunrayV2、YunLink ROS Bridge 和网络地址已启动。
2. Bridge 的 Entity Directory 中出现 `kind == "sunray.uav"` 的实体。
3. 连接协商成功 `org.yunlink.mobility` 和 `com.yundrone.sunray` Profile。
4. `vehicle.state.frame_id`、位置和飞控状态持续更新，且 `vehicle.state.fresh` 为 `True`。
5. 首次控制前确认设备周围安全、控制器允许外部控制、起降区域没有障碍物。
6. 先用 `01_discover.py`、`02_connect_and_inspect.py` 和 `03_watch_state.py` 做只读检查，
   再运行会产生运动的示例。

## 错误处理

- Bridge 不可达：`ConnectionError`
- 实体不存在或名称不唯一：`EntityNotFoundError`
- Action 被设备或 Bridge 拒绝：`ActionFailedError`
- Action 超时：`TimeoutError`
- 连接中断：`DisconnectedError`

断线不会自动重放起飞、移动、航点或降落。应用程序必须重新读取状态，确认设备当前状态后，再明确决定是否重新提交动作。

## 仿真与真实设备的边界

本机和 HomeUbuntu20 的仿真只能证明 YunLink 编码、Bridge 映射、Session/Attach/authority、状态流和动作闭环；
它不能证明真实飞控、真实定位、真实传感器、网络质量或物理安全。真实设备的最终验收仍需要在拆桨/安全模式和现场安全流程下单独完成。

真实 Bridge 使用不同端口或实体名称时，只改变连接地址和 `vehicle(...)` 参数，不需要修改 SDK 或复制一套真实设备 API。

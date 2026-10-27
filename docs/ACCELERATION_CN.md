# 加速度补偿

要求 Python SDK 1.5.0、YunLink binding 2.0.4，以及支持 Sunray Profile 2.20 的 Bridge。
旧 Bridge 仍可使用原有控制接口；调用本接口时会明确报告版本不支持。

该接口将算法输出叠加到已有位置/速度参考上。三轴使用**世界 NED**（北、东、下）约定，
单位 **m/s²，不含重力**。无补偿时为 `(0, 0, 0)`，不要传 `9.8`。
实际轴向沿用控制器当前 world 约定，机载只做 `ENU=(NED.y,NED.x,-NED.z)` 换轴。

仅 `SunrayPosController`（ROS `controller_type=0`）消费此输入，状态须为 HOVER/MOVE，
定位有效、没有人工接管。控制器中的 `matlab_cmd_param.enable` 和
`apply_to_sunray_pos` 须为 true。默认幅值上限 0.5 m/s²，超出由控制器等比缩放。
默认输入话题为 `${agent_key}/sunray/uav_control/control_cmd_matlab`；
原先使用 Sync 镜像话题的设备需在现有参数中改回此本地入口并重启控制 Feature。

```python
import time
from yunlink_python import connect

with connect("192.168.31.236:9696") as client:
    uav = client.vehicle("<设备目录中的 UAV ID>")
    # 这里假定 UAV 已起飞并悬停。补偿通道本身不负责起飞。
    with uav.acceleration_compensation() as channel:
        for _ in range(100):
            channel.update(0.01, 0.0, 0.0)  # 替换为这一拍算法算出的新值。
            time.sleep(0.01)
    # 离开 with 时取消补偿，原位置/速度参考继续运行。
```

每次 `update(ax, ay, az)` 发送一个新样本，不会后台重发。建议算法以 100 Hz 更新；
300 ms 没有新输入时通道过期，需显式重新打开，不能继续更新旧 Action。
客户端无需与机载同步 ROS 时钟，Bridge 用机载 ROS 时间为每个新样本标记时间戳。
该 TCP 控制接口不承诺实时调度或固定网络延迟。

- `channel.action`：原有 `ActionHandle`，可读 `phase`、`detail`、`done`，也可 `wait()`。
- `channel.update(ax, ay, az)`：更新当前通道，NaN/Inf 拒绝发送。
- `channel.cancel()`：清零并等待取消确认，不调用 Hover、不取消原飞行任务。
- `uav.cancel()`：仍用于原运动任务的取消；要单独停止补偿，请使用 `channel.cancel()`。

断线、detach、失去 Sunray authority 或 Bridge 判定输入不可用时撤掉补偿。
断线重连不重放补偿或飞行动作。控制器本身还保留 0.3 s 输入超时，Bridge 退出后同样生效。
MATLAB 适配在下一阶段实现，本版不增加新的 MATLAB 函数。

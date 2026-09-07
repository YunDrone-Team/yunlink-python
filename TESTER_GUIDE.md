# YunLink Python SDK 测试人员使用指南

仓库地址：<https://github.com/YunDrone-Team/yunlink-python>

这个 SDK 通过 YunLink Bridge 控制 SunrayV2 设备，不连接 ROS。测试人员只需要 Python、YunLink Python binding 和本 SDK。
仿真与真实设备使用同一套 Python API；区别只在连接到哪个 Bridge 和现场安全条件。

## 1. 安装

建议使用 Python 3.10、3.11 或 3.12 的虚拟环境。当前版本不从 PyPI 安装，使用 GitHub Release 附件：

1. 从 YunLink 仓库构建或取得与操作系统匹配的 `yunlink` Python binding wheel。
2. 安装 `yunlink` wheel。
3. 打开本仓库的 GitHub Release 页面，下载 `yunlink_python-1.0.0-py3-none-any.whl`。
4. 安装 SDK wheel：

```bash
python -m pip install /path/to/yunlink-*.whl
python -m pip install /path/to/yunlink_python-1.0.0-py3-none-any.whl
python -c "import yunlink_python; print(yunlink_python.__version__)"
```

也可以直接从源码安装：

```bash
git clone https://github.com/YunDrone-Team/yunlink-python.git
cd yunlink-python
python -m pip install -e .
```

## 2. 连接测试环境

设置 Bridge 地址和明确的实体 ID：

```bash
export YUNLINK_ADDRESS=192.168.31.236:9696
export YUNLINK_VEHICLE=<entity_uid>
export YUNLINK_UGV=<entity_uid>
```

没有设置 `YUNLINK_ADDRESS` 时，SDK 会尝试 UDP 搜索唯一 Bridge。网络中存在多个 Bridge 时，必须先用 `endpoint_uid` 选择目标；网络不允许广播时，必须显式设置地址。

当前 HomeUbuntu20 仿真环境通常是：

```text
Bridge: 192.168.31.236:9696
UAV:    uav1, uav2, uav3
UGV:    ugv1, ugv2, ugv3
```

## 3. 推荐测试顺序

### 3.1 只读搜索

不会连接设备，也不会发送控制动作：

```bash
python examples/01_discover.py
```

应看到 Bridge 地址、`com.yundrone.sunray` Profile，以及 UAV/UGV 实体目录。

如果局域网有多台 Bridge，先搜索并使用 Bridge ID 选择脚本：

```bash
python examples/10_discover_select_connect.py --id <endpoint_uid>
```

多人/多机局域网测试时，必须先保存脚本打印的 `endpoint_uid` 和每台设备的 `entity_uid`，再用 ID 选择，
不要依赖默认第一台设备。只读检查可以运行：

```bash
python examples/13_multi_device_state.py --seconds 30
```

仿真多机控制可以运行：

```bash
python examples/11_multi_device_control.py
python examples/12_multi_uav_waypoints.py
```

这两个脚本对每个设备独立提交动作并单独报告失败，不代表编队控制。

脚本先完整打印搜索结果，再只连接指定的 `endpoint_uid`。`endpoint_uid` 是 Bridge 的选择 ID，
`entity_uid` 是 Bridge 下具体 UAV/UGV 的选择 ID；两者都不是临时列表序号。
如果不传 `--entity`，脚本只连接 Bridge 并打印完整实体目录，不会 attach 或发送飞行动作。

### 3.2 建立连接并读取目录

```bash
python examples/02_connect_and_inspect.py --address <bridge-address>
```

此步骤只连接 Bridge 并读取目录，应看到：

- Session 建立成功
- UAV/UGV 实体名称、`entity_uid`、类型、属性和能力

此时还没有 attach UAV，也没有申请飞控权限。

### 3.3 持续读取状态

```bash
python examples/03_watch_state.py --address <bridge-address> --entity <entity_uid> --seconds 10
```

检查 `connected=True`、`fresh=True`，位置和电池数据持续更新。此步骤仍然不会发送飞行动作。

### 3.4 UAV 基础控制

确认现场安全后运行：

```bash
python examples/04_flight_basics.py --address <bridge-address> --entity <entity_uid>
```

脚本依次执行：起飞、前进、后退、左移、右移、上移、下移、MoveTo、悬停和降落。
脚本异常退出时，先确认设备状态，再手动通过 GCS 或其他安全手段处理，不要盲目重复启动。

### 3.5 Planner 多航点

```bash
python examples/05_waypoints.py --address <bridge-address> --entity <entity_uid>
```

检查输出中的 Planner 主状态、任务状态、航点序号、距离、停留时间和失败原因。脚本结束时会尽力降落。

### 3.6 Action 取消

```bash
python examples/06_cancel_action.py --address <bridge-address> --entity <entity_uid> --after 2
```

检查是否能看到非阻塞 Action 的 `phase` 和 `progress`，以及取消后的 `CANCELLED` 结果。取消后脚本会执行降落清理。

### 3.7 UGV

```bash
python examples/07_ugv_control.py --address <bridge-address> --entity <entity_uid>
```

检查 UGV 的状态、MovePoint、短时速度租约和 Hold。UGV 测试不会调用 UAV 飞行接口。

### 3.8 异常路径

```bash
python examples/08_errors.py
```

检查实体不存在、连接失败、动作失败和超时是否能得到清晰错误。不要把异常输出改成“成功”。

## 4. Python 最小控制脚本

测试人员可以用下面的脚本验证最小闭环：

```python
import os

from yunlink_python import connect

address = os.getenv("YUNLINK_ADDRESS", "192.168.31.236:9696")
vehicle_name = os.getenv("YUNLINK_VEHICLE")

with connect(address) as client:
    # 连接 Bridge 后先打印目录；这一步不会 attach 或发送控制命令。
    for device in client.entities():
        print(device.uid, device.name, device.kind)

    # 使用目录中确认过的 entity_uid；不允许省略或默认选择第一台 UAV。
    if not vehicle_name:
        raise SystemExit("请设置 YUNLINK_VEHICLE 为目录中的 entity_uid 或设备名称")
    uav = client.vehicle(vehicle_name)
    print("before:", uav.state)
    try:
        print("takeoff:", uav.takeoff(1.0, timeout=30))
        start = uav.state.position
        print("move_to:", uav.move_to(start.x + 0.3, start.y, 1.0, timeout=60))
        print("hover:", uav.hover(timeout=15))
    finally:
        if not uav.state.landed:
            print("land:", uav.land(timeout=30))
```

## 5. 结果记录

每次测试至少记录：

```text
日期和测试人：
操作系统与 Python 版本：
SDK commit 或 wheel 文件：
YunLink binding 版本：
Bridge 地址：
实体 UID：
测试脚本：
开始状态：
动作结果和耗时：
最终状态：
异常文本（如有）：
Bridge/Sunray 日志路径（如有）：
```

动作结果中的 `SUCCEEDED`、`FAILED`、`CANCELLED` 要原样记录。连续速度控制租约到期返回 `CANCELLED` 是正常停止语义，不能直接当成飞行失败；同时应核对设备是否已经停止运动。

## 6. 真实设备注意事项

- 先运行 `01_discover.py`、`02_connect_and_inspect.py` 和 `03_watch_state.py`，确认状态新鲜后再控制。
- 真实设备测试必须遵守现场飞行、拆桨或安全模式规定。
- 断线时 SDK 不会自动重放未完成的起飞、移动、航点或降落动作。
- `ConnectionError`、`EntityNotFoundError`、`ActionFailedError`、`TimeoutError` 和 `DisconnectedError` 都是需要记录的有效测试结果。
- 仿真通过不等于真实飞控、定位、传感器和物理安全已经验收。

更详细的 API 说明见 [`examples/README.md`](examples/README.md) 和 [`COMPATIBILITY.md`](COMPATIBILITY.md)。

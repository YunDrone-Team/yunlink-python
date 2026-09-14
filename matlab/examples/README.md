# YunLink MATLAB 示例

示例按「搜索 Bridge、连接 Bridge、查看目录、选择设备、读取状态、再控制」的顺序排列。
先运行 `00_setup.m`，再按编号往下做。每个脚本开头的 `address` / `uavUid` / `ugvUid` 请改成现场确认过的值。

`yunlink_connect` 只连接 Bridge。`yunlink_entities` 只读目录。只有 `yunlink_vehicle` / `yunlink_ugv` 才会 attach 设备。

## 0. 配置 Python 与通信库

打开 `00_setup.m`，填写本机 Python 3.10–3.13 可执行文件路径，以及解压后的发布包目录，然后 Run。这一步不连接无人机。

## 1. 搜索 Bridge

`01_discover.m` 只做 UDP 搜索，不连接、不 attach、不控制。记下输出中的 `host:port` 和 `entity_uid`。

## 2. 连接并查看目录

`02_connect_and_inspect.m` 建立 Session 并打印设备目录，不 attach，不发送控制。

## 2.1 按 Bridge ID 选择连接

`10_discover_select_connect.m` 先列出全部 Bridge，再按 `bridgeId` 连接指定那一台，然后 attach 指定 `entity_uid`。不会默认连列表里的第一台。

## 3. 读取状态

`03_watch_state.m` attach 一架 UAV 并打印状态，不发送飞行指令。`read_state_demo.m` 是同一类只读脚本。

## 4. 基础飞行

`04_flight_basics.m` 会起飞、前后左右上下、目标移动、悬停和降落。第一次请只对仿真实体运行。`basic_flight_demo.m` 是精简版。

## 5. 航点

`05_waypoints.m` 起飞后提交两点 Planner 航线，然后降落。

## 6. 取消动作

`06_cancel_action.m` 启动一次较长移动后取消，再悬停降落。

## 7. 无人车

`07_ugv_control.m` 对 UGV 做点位移动、短时速度控制和 Hold。

## 8. 异常

`08_errors.m` 演示实体不存在和动作超时的处理。

## 9. 多设备

`11_multi_device_control.m` attach 目录中全部 UAV/UGV 并打印状态，不飞。
`12_multi_uav_waypoints.m` 给每架 UAV 一条短航线，会发送飞行指令。
`13_multi_device_state.m` 连续打印多设备状态。
`14_observe_live.m` 在命令窗口刷新遥测，Ctrl-C 结束。

## 安全

`04`、`05`、`06`、`07`、`12` 会发送真实控制。运行前确认目标是允许运动的实体，周围没有人员和障碍。

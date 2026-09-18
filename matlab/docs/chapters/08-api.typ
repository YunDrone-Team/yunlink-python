#import "../vendor/mantys/src/mantys.typ": *

= 函数参考

本章列出工具箱中的 MATLAB 封装。行为以 Python SDK 为准。命令窗口中的函数名形如 `yunlink_takeoff`。

== 安装与运行时

#command("yunlink_examples")[
  将当前文件夹切换到工具箱的 `examples` 目录，并在桌面版打开文件浏览器与 `ex00_setup.m`。这是教程入口。
]

#command("yunlink_setup", arg[pythonExe], arg[bundleDir])[
  将发布包内的 `yunlink` 与 `yunlink_python` 轮子安装到指定 Python，并记录路径。不使用 pip。64 位 Windows 仅选择 `win_amd64`。
  #argument("pythonExe", types: ("string",))[Python 3.10–3.13 可执行文件路径。]
  #argument("bundleDir", types: ("string",))[解压后的发布包目录，须包含 `.mltbx` 与 `wheels`。]
]

#command("yunlink_update")[
  与 `yunlink_setup` 相同，用于更换发布包后重新安装轮子。
]

#command("yunlink_prepare_runtime")[
  各控制函数会间接调用。恢复上次选择的 Python 并检查本 MATLAB 是否支持该解释器。一般不必手写。
]

== 发现与连接

#command("yunlink_discover", arg[timeout])[
  在局域网搜索 Bridge。使用 UDP 9697，不连接、不飞行。
  #argument("timeout", default: 5, types: ("double",))[搜索持续时间，单位秒。]
]

返回结构体数组，常用字段：`endpointUid`、`ip`、`tcpPort`、`address`、`discoveryId`、`name`、`entities`。

#command("yunlink_connect", arg[address])[
  使用 TCP 9696 建立会话。
  #argument("address", types: ("string",))[形如 `192.168.1.5:9696`。请使用搜索打印的连接地址。]
]

#command("yunlink_close", arg[client])[
  关闭会话。建议配合 `onCleanup`。
]

#command("yunlink_entities", arg[client])[
  读取设备目录，不 attach。字段为 `uid`、`name`、`kind`。
]

#command("yunlink_vehicle", arg[client], arg[entity_uid])[
  按 `entity_uid` attach 无人机并订阅遥测。不自动起飞。
]

#command("yunlink_ugv", arg[client], arg[entity_uid])[
  按 `entity_uid` attach 无人车并订阅遥测。
]

== UAV 状态

#command("yunlink_state", arg[vehicle])[
  返回 MATLAB 结构体。飞行前请确认 `fresh` 为真。
]

#command("yunlink_monitor", arg[vehicle], arg[seconds], arg[options])[
  只采样、不控制。
  #argument("seconds", types: ("double",))[监视时长，单位秒。]
  #argument("options")[可选结构体，含 `print` 与 `period_s`。]
]

== UAV 控制

下列函数会申请控制权。请仅在允许运动的环境中调用。

#command("yunlink_takeoff", arg[vehicle], arg[height_m], arg[timeout])[
  相对高度起飞。
  #argument("height_m", types: ("double",))[相对高度，单位米。例如 `1.0` 表示约 1 米。]
  #argument("timeout", default: 30, types: ("double",))[等待起飞结束的超时，单位秒。]
]

#command("yunlink_hover", arg[vehicle], arg[timeout])[
  进入悬停。
  #argument("timeout", default: 15, types: ("double",))[等待超时，单位秒。]
]

#command("yunlink_land", arg[vehicle], arg[timeout])[
  降落。默认超时 30 秒。
]

#command("yunlink_translate", arg[vehicle], arg[direction], arg[speed_mps], arg[duration_s], arg[timeout])[
  机体轴短时平移。方向为 `forward`、`backward`、`left`、`right`、`up`、`down`。
  #argument("speed_mps", default: 0.15, types: ("double",))[速度，单位米/秒。]
  #argument("duration_s", default: 0.8, types: ("double",))[持续秒。大约位移等于速度乘以时间。]
  #argument("timeout", default: 15, types: ("double",))[等待超时，单位秒。]
]

#command("yunlink_position_control", arg[vehicle], arg[x], arg[y], arg[z], arg[yaw_rad], arg[timeout])[
  直接位置控制，不走 Planner。
  #argument("x", types: ("double",))[目标 $x$，单位米。]
  #argument("y", types: ("double",))[目标 $y$，单位米。]
  #argument("z", types: ("double",))[目标 $z$，单位米。]
  #argument("yaw_rad", default: 0, types: ("double",))[偏航，单位弧度。]
  #argument("timeout", default: 120, types: ("double",))[等待超时，单位秒。]
]

#command("yunlink_velocity_control", arg[vehicle], arg[vx], arg[vy], arg[vz], arg[options])[
  速度控制。`options` 可含 `duration_s`、`lease_ms`、`timeout`、`wait`、`frame_id`、`height_lock_m`。租约到期常为 `CANCELLED`。
]

#command("yunlink_cancel", arg[vehicle], arg[timeout])[
  取消当前动作。默认超时 15 秒。
]

#command("yunlink_return_home", arg[vehicle], arg[timeout])[
  返航。默认超时 120 秒。须明确调用。
]

#command("yunlink_emergency_lock", arg[vehicle], arg[confirmed], arg[timeout])[
  紧急上锁。第二个参数必须为 `true`，以确认该操作。
]

#command("yunlink_move_to", arg[vehicle], arg[x], arg[y], arg[z], arg[timeout])[
  Planner 单目标移动。*示例主线未覆盖。* 参数 $x$、$y$、$z$ 单位为米，默认超时 60 秒。
]

#command("yunlink_waypoint", arg[vehicle], arg[x], arg[y], arg[z], arg[timeout])[
  Planner 单航点。*示例主线未覆盖。* 默认超时 120 秒。
]

#command("yunlink_waypoints", arg[vehicle], arg[points], arg[timeout])[
  Planner 多航点。`points` 为 $N times 3$ 矩阵，单位米。*示例主线未覆盖。*
]

#command("yunlink_command", arg[vehicle], arg[kind], arg[options])[
  通用动作入口。`kind` 可为 `takeoff`、`position`、`velocity`、`hover`、`return_home`、`land`、`emergency_lock`。
]

#command("yunlink_mapping_start", arg[device], arg[timeout])[
  启动 Livox 点云累积。UAV 与 UGV 均可。仿真中传感器常不可用。
]

#command("yunlink_mapping_stop", arg[device], arg[timeout])[
  停止点云累积。
]

== UGV 控制

#command("yunlink_ugv_state", arg[ugv])[
  无人车状态。请确认 `fresh` 后再移动。
]

#command("yunlink_ugv_move_to", arg[ugv], arg[x], arg[y], arg[timeout])[
  平面点位。
  #argument("x", types: ("double",))[目标 $x$，单位米。]
  #argument("y", types: ("double",))[目标 $y$，单位米。]
  #argument("timeout", default: 60, types: ("double",))[等待超时，单位秒。]
]

#command("yunlink_ugv_velocity", arg[ugv], arg[vx], arg[duration_s], arg[timeout])[
  短时速度租约。
  #argument("vx", types: ("double",))[前进速度，单位米/秒。]
  #argument("duration_s", default: 1.0, types: ("double",))[持续秒。]
]

#command("yunlink_ugv_hold", arg[ugv], arg[timeout])[
  在当前位姿保持。默认超时 15 秒。
]

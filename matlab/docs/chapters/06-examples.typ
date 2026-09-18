#import "../vendor/mantys/src/mantys.typ": *

= 示例教程

本章按编号说明每一个示例。请先完成第 4 章的配置，并将当前文件夹保持为 `examples`（执行 `yunlink_examples` 即可）。

运行方式有两种，效果相同：

- 在当前文件夹中双击 `.m` 文件，在编辑器中点击绿色「运行」；
- 在命令窗口输入脚本名后回车，例如 `ex01_discover`。

== 总表

#figure(
  table(
    columns: (auto, auto, auto, 1fr),
    align: (left, left, left, left),
    stroke: 0.4pt,
    inset: 5pt,
    [*编号*], [*脚本*], [*会发控制*], [*学习目标*],
    [00], [`ex00_setup.m`], [否], [配置 Python 并安装通信库],
    [01], [`ex01_discover.m`], [否], [UDP 搜索，抄写连接地址与 entity_uid],
    [02], [`ex02_connect_and_inspect.m`], [否], [TCP 连接，只打印目录],
    [03], [`ex03_watch_state.m`], [否], [attach 后读取状态；fresh 为 1 方可飞行],
    [04], [`ex04_flight_basics.m`], [会飞], [起飞约 1 米，机体轴短移，悬停，降落],
    [05], [`ex05_cancel_action.m`], [会飞], [非阻塞移动后取消],
    [06], [`ex06_ugv_control.m`], [会走], [无人车点位、短时速度、Hold],
    [07], [`ex07_errors.m`], [可能失败起飞], [观察错误信息的形式],
    [08], [`ex08_discover_select_connect.m`], [否], [多台 Bridge 时按 Bridge ID 选择],
    [09], [`ex09_multi_device_control.m`], [否], [attach 全部设备并只读],
    [10], [`ex10_multi_device_state.m`], [否], [连续打印多设备状态约 8 秒],
    [11], [`ex11_observe_live.m`], [否], [命令窗口刷新遥测],
    [12], [`ex12_live_check.m`], [会飞/会走], [现场全量检查],
    [—], [`read_state_demo.m`], [否], [`ex03` 的短版],
    [—], [`basic_flight_demo.m`], [会飞], [`ex04` 的短版],
  ),
  caption: [示例一览。请按编号连续进行，中间不跳号。],
)

== ex00 配置 Python

*目的*：把发布包内的通信库安装到本机 Python。不连接、不飞行。

*操作*：打开 `ex00_setup.m`，确认 `pythonExe` 与 `bundleDir`，点击「运行」。成功时命令窗口会打印 Python 路径与 Bundle 路径，并提示下一步运行 `ex01_discover`。

*失败时*：若提示找不到 Python，请按第 2 章填写完整的 `python.exe` 路径。若提示找不到 Bundle，请将 `bundleDir` 指到含有 `.mltbx` 的解压目录。

== ex01 搜索 Bridge

*目的*：在局域网中搜索 YunLink Bridge，并抄写后续所需的标识。不连接 TCP，不 attach。

*操作*：在命令窗口输入 `ex01_discover`。脚本默认搜索 5 秒。

*预期输出*：每个 Bridge 打印「连接地址」（写入 `YUNLINK_ADDRESS=`）、「Bridge ID」（多台时写入 `YUNLINK_BRIDGE_ID=`），以及设备表。设备表的*第一列*是 `entity_uid`，写入 `YUNLINK_UAV=` 或 `YUNLINK_UGV=`。

*失败时*：请阅读第 5 章关于防火墙与写死地址的说明。

== ex02 连接并查看目录

*目的*：使用 TCP 9696 建立会话，只读取设备目录。

*操作*：保存 `yunlink.env` 后运行 `ex02_connect_and_inspect`。若未填写地址且网络中仅有一台 Bridge，脚本会采用搜索结果。

```matlab
client = yunlink_connect(address);
infos = yunlink_entities(client);
```

`yunlink_connect` 不选中任何飞机。`yunlink_entities` 不申请控制权。请将表中的 `entity_uid` 写入环境文件后进入 `ex03`。

== ex03 只读状态

*目的*：attach 一架无人机并打印遥测。不飞行。

```matlab
uav = yunlink_vehicle(client, uavUid);
pause(0.5);
state = yunlink_state(uav);
```

请确认 `state.fresh` 为 1（真）。为 0 表示遥测过旧，不得起飞。`position` 的单位是米，`velocity` 的单位是米/秒，`batteryPercent` 是百分数。`armed` 与 `landed` 仅为状态位，本工具箱不提供单独的解锁函数。

地面站已经控制该机时，本步骤仍然只读。

== ex04 基础飞行

*目的*：起飞、机体轴短时平移、悬停、降落。*会发出真实控制。*

*运动量（理想情况）*：

- 起飞相对高度 `height = 1.0`，单位米，即约 1 米。
- 前进与后退：速度 0.15 米/秒，持续 0.8 秒，大约位移 0.12 米。
- 左移与右移：速度 0.15 米/秒，持续 0.5 秒，大约位移 0.075 米。
- 上升与下降：速度 0.1 米/秒，持续 0.5 秒，大约位移 0.05 米。

请在周围预留前后左右各约 1 米、上方约 2 米。实际轨迹受惯性与定位误差影响，可能略大于上述数值。

关键调用：

```matlab
yunlink_takeoff(uav, height, 30);
yunlink_translate(uav, "forward", 0.15, 0.8, 15);
yunlink_hover(uav, 15);
yunlink_land(uav, 30);
```

`yunlink_takeoff` 的第二个参数是高度（米），第三个参数是等待超时（秒）。`yunlink_translate` 的第三个参数是速度（米/秒），第四个参数是持续秒，第五个参数是等待超时秒。租约结束后结果常为 `CANCELLED`，表示本次速度租约已结束。

若飞机已在空中，脚本会跳过起飞，以免飞控以 INIT 拒绝。`try` / `finally` 会在出错时仍尝试降落。

== ex05 取消动作

*目的*：起飞后发出非阻塞移动，随即取消，再悬停降落。会飞。

起飞高度仍为 1.0 米。`move_to` 的目标在当前 $x$ 方向再增加 2.0 米（世界系，单位米）。`wait=false` 使命令立即返回；`pause(0.4)` 等待 0.4 秒以便任务发出，然后 `yunlink_cancel(uav, 15)`。飞机不会走完那 2 米。

== ex06 无人车

*目的*：无人车点位移动、短时速度与 Hold。不飞行，会行走。

须在 `YUNLINK_UGV=` 填写无人车的 `entity_uid`。`yunlink_ugv_move_to` 的第二、三个参数是目标 $x$、$y$（米），这里为当前 $x$ 加 0.3 米；第四个参数 45 是等待超时秒。`yunlink_ugv_velocity(ugv, 0.1, 0.5, 15)` 表示 0.1 米/秒持续 0.5 秒，大约 0.05 米。请等待状态新鲜后再 `move_to`。

== ex07 错误信息

*目的*：故意触发失败，以便识别报错文本。正常情况下起飞会因 0.001 秒超时而失败，飞机不应真正起飞。

脚本首先对不存在的 `does-not-exist` 调用 `yunlink_vehicle`，预期得到实体未找到。随后 `yunlink_takeoff(uav, 1.0, 0.001)` 中的 `1.0` 是高度（米），`0.001` 是超时（秒）。

== ex08 按 Bridge ID 选择

*目的*：当网络中有多台 Bridge 时，按 `YUNLINK_BRIDGE_ID=` 选择其中一台。不飞行。

Bridge ID 是 `ex01` 打印的`endpoint_uid` 短字符串。未填写且仅发现一台时，脚本会暂用该台。

== ex09 多设备只读

*目的*：对目录中每一架无人机与每一辆无人车执行 attach，并打印位置。不飞行、不行走。地面站已控制这些设备时，本脚本仍可读取。

== ex10 连续打印状态

*目的*：在约 8 秒内反复刷新全部设备状态。`seconds = 8` 表示监视时长。两次打印间隔 0.5 秒。本示例只读取遥测。

== ex11 命令窗口遥测

*目的*：清屏刷新遥测。桌面环境下 `seconds = 0` 表示一直运行，请用 Ctrl-C 结束。无桌面（`-batch`）时自动改为 2 秒，以免进程挂起。`hz = 2` 表示约每 0.5 秒刷新一次。

若填写了 `YUNLINK_UAV=`，则只显示该实体。

== ex12 现场全量检查

*目的*：一次性覆盖搜索、连接、目录、attach、状态、错误路径，以及起飞、平移、悬停、降落（若有无人机）和无人车点位（若有无人车）。

命令窗口可输入 `ex12_live_check` 或 `yunlink_live_check`。桌面环境会弹出对话框，默认按钮为「继续飞」。

运动量在 `yunlink_live_check.m` 中：起飞 1.0 米；前进速度 0.15 米/秒、持续 0.6 秒，大约 0.09 米；无人车 $x$ 增加 0.3 米。每一项打印 `PASS`、`FAIL` 或 `SKIP`。

#info-alert[
  验收主线不覆盖 Planner 航点。`yunlink_waypoints` 等函数仍可在第 8 章查阅，但 `ex12` 不会调用它们。
]

== 两个短版脚本

`read_state_demo.m` 与 `ex03` 相同目的，注释较少。`basic_flight_demo.m` 会起飞到 1.5 米，并将位置控制到 $x=2.0$、$y=0.0$、$z=1.5$（单位米）。完整注释请阅读 `ex04_flight_basics.m`。

# YunLink MATLAB 示例（这就是教程）

装好 Toolbox 之后，请先按编号跑 `ex00` 到 `ex12`，对着脚本里的注释看每一行在干什么。熟悉示例后再查阅 [`../developer/API.md`](../developer/API.md)。

从安装 MATLAB 与打开命令窗口讲起的逐步说明书：Typst 源码见 [`../docs/README.md`](../docs/README.md)，可自行编译 PDF；GitHub Release 提供已编译的 `yunlink-matlab-manual.pdf`。

不要改脚本中间的变量。连接地址和 `entity_uid` 写在本目录 `yunlink.env`（没有就直接改 `yunlink.env.example`）。程序先读环境变量，再 `yunlink.env`，再 `yunlink.env.example`。

## 第一次怎么跑

1. 命令窗口输入 `yunlink_examples`（不要带 `.m`）。左侧会打开本目录。
2. 打开 `ex00_setup.m`，点绿色 **Run**。配 Python 3.10–3.13 和 zip 包。
3. 运行 `ex01_discover`。把打印的 **连接地址** 写入 `YUNLINK_ADDRESS=`，把表里 **entity_uid** 那一列写入 `YUNLINK_UAV=` 或 `YUNLINK_UGV=`。不要填 `uav1`。
4. 按编号往下。`ex03` 只读；`ex04` 起会飞。一次跑完用 `ex12_live_check`。

`yunlink_connect` 只连 Bridge。`yunlink_entities` 只读目录。只有 `yunlink_vehicle` / `yunlink_ugv` 才会 attach。地面站已经连上并控制设备时，MATLAB 仍可只读遥测，不必申请控制权。起飞、平移、Hold 才会发控制。

## 每个 example 做什么

| 编号 | 脚本 | 会发控制 | 学什么 |
| --- | --- | --- | --- |
| 00 | `ex00_setup.m` | 否 | 给 MATLAB 配 Python，把 zip 里的通信库装进去 |
| 01 | `ex01_discover.m` | 否 | UDP 9697 搜索 Bridge，抄连接地址和 entity_uid |
| 02 | `ex02_connect_and_inspect.m` | 否 | TCP 9696 连接，只打印设备目录 |
| 03 | `ex03_watch_state.m` | 否 | attach 一架 UAV，读状态。`fresh=1` 才能飞 |
| 04 | `ex04_flight_basics.m` | **会飞** | 起飞约 1 m，机体轴短移，悬停，降落 |
| 05 | `ex05_cancel_action.m` | **会飞** | 起飞后非阻塞移动，再 `yunlink_cancel` |
| 06 | `ex06_ugv_control.m` | **会走** | 无人车点位约 0.3 m、短时速度、Hold |
| 07 | `ex07_errors.m` | 可能一次失败起飞 | 看错误信息长什么样 |
| 08 | `ex08_discover_select_connect.m` | 否 | 多台 Bridge 时按 Bridge ID 选一台 |
| 09 | `ex09_multi_device_control.m` | 否 | attach 目录里全部 UAV/UGV，只读 |
| 10 | `ex10_multi_device_state.m` | 否 | 连续打印多设备状态，约 8 秒 |
| 11 | `ex11_observe_live.m` | 否 | 命令窗口刷新遥测，桌面 Ctrl-C 结束 |
| 12 | `ex12_live_check.m` | **会飞/会走** | 现场全量检查：搜索、连接、起飞、平移、降落 |
| — | `read_state_demo.m` | 否 | `ex03` 的短版 |
| — | `basic_flight_demo.m` | **会飞** | `ex04` 的短版 |

`ex04` 运动量（理想情况）：起飞高度 **1 米**；前进/后退约 **12 cm**（0.15 m/s × 0.8 s）；左右约 **7.5 cm**（0.15 m/s × 0.5 s）；升降约 **5 cm**。周围请空出前后左右各 1 米、头上 2 米。

`yunlink_translate` 的数字：**第 3 个是速度 m/s，第 4 个是持续秒，第 5 个是等待超时秒。** 不是「飞 0.15 米」。

## 搜不到 Bridge / Windows 防火墙

搜索 **不是** 连 TCP 9696。本机向 **UDP 9697** 发查询：

- `255.255.255.255`（有限广播，不少 Wi-Fi 会丢掉）
- 本机网卡广播地址
- 本网段 `/24` 里每个 IP 的单播（所以家用 Wi-Fi 也能搜到）

Bridge 用 9697 回答，然后再用 TCP 9696 建 Session。

Windows 第一次跑 MATLAB 或 `python.exe` 时，可能弹出全屏「Windows 安全警报」。请勾选 **专用网络** 并允许访问。点取消、或只允许公用网络，就会搜不到或偶发失败。这和以前测试员在 0.12 上遇到的拦截是一类问题。

也可以跳过搜索：在 `yunlink.env` 写死

```
YUNLINK_ADDRESS=192.168.1.5:9696
```

地址用 `ex01` 打印的「连接地址」，不要用文档里的示例 IP。

## 如何运行脚本

| MATLAB | 对应习惯 |
| --- | --- |
| 左侧 Current Folder | `pwd` 里的文件列表 |
| 中间 Editor | 打开的源文件 |
| 下方 Command Window | 交互式 shell |
| 绿色 **Run** | 执行当前脚本 |

在 Command Window 输入脚本名（不要带 `.m`）：`ex01_discover`。Current Folder 必须是 `examples`；刚打开 MATLAB 先 `yunlink_examples`。

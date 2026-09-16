# YunLink MATLAB 示例

把用户当第一次用 MATLAB 的人：不要改脚本中间的变量。目标写在本目录 `yunlink.env`。

## 第一次怎么跑

1. 运行 `yunlink_examples`，左侧会打开本目录。
2. 打开 `ex00_setup.m`，点绿色 **Run**。配 Python 3.10–3.13 和 zip 包。
3. 配置写在 `yunlink.env`；没有这份文件就直接改同目录的 `yunlink.env.example`。程序先读环境变量，再 `yunlink.env`，再 `yunlink.env.example`。
4. 运行 `ex01_discover`。把打印的 **连接地址** 写入 `YUNLINK_ADDRESS=`，把表里 **entity_uid** 那一列写入 `YUNLINK_UAV=` 或 `YUNLINK_UGV=`。不要填 `uav1`。
5. 保存后再按编号往下：`ex02` 看目录，`ex03` 只读状态，`ex04` 起会飞。

`yunlink_connect` 只连 Bridge。`yunlink_entities` 只读目录。只有 `yunlink_vehicle` / `yunlink_ugv` 才会 attach。

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

## 编号说明

- `ex00` 配 Python，不连飞机
- `ex01` 搜索，抄地址和 entity_uid
- `ex02` 连接并打印带表头的目录
- `ex03` / `read_state_demo` 只读 UAV
- `ex04` / `basic_flight_demo` 会飞
- `ex05` 航点，会飞
- `ex06` 取消，会飞
- `ex07` 无人车，会走
- `ex08` 看错误信息
- `ex10` 多 Bridge 时按 Bridge ID 选
- `ex11` `ex13` `ex14` 多机只读
- `ex12` 多机短航线，会飞
- `ex99_live_check` / `yunlink_live_check` 现场一次跑完搜索、连接、目录、状态、错误路径；默认不飞

`04`、`05`、`06`、`07`、`12`、`basic_flight_demo` 会发真实控制。周围不要有人和障碍。

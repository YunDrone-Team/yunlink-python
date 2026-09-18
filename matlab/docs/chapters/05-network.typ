#import "../vendor/mantys/src/mantys.typ": *

= 搜索与网络

== 搜索原理与机制

`ex01_discover` 与 `yunlink_discover` 向局域网发送 UDP 查询，端口为 *9697*。查询完成后，使用 `yunlink_connect` 在 TCP *9696* 上建立会话；订阅某一设备的遥测时再调用 `yunlink_vehicle` 或 `yunlink_ugv`。

查询会发往：

- `255.255.255.255`（有限广播；部分 Wi-Fi 会丢弃）；
- 本机网卡的广播地址；
- 本网段 `/24` 内除本机以外的每个 IPv4 地址（单播）。

Bridge 仍通过 UDP 9697 回答。之后，`yunlink_connect` 才使用回答中的 IP 与 *TCP 9696* 建立会话。

== Windows 防火墙

Windows 第一次运行 MATLAB 或 `python.exe` 时，可能弹出全屏「Windows 安全警报」。请勾选*专用网络*并允许访问。若点击取消，或仅允许公用网络，则可能完全搜不到，或偶发失败。

这与历史上在 0.12 版本测试中遇到的拦截属于同一类问题：操作系统拦截了 UDP 9697 的收发。

部分 Windows 主机会在对 `/24` 探测无进程侦听时返回 ICMP Port Unreachable，并在下一拍 `recvfrom` 上表现为 `WinError 10054`。当前 SDK 会忽略该重置并继续监听。若您仍在命令窗口看到 10054，请重新运行 `ex00_setup` 安装发布包内的 Python 轮子，然后关闭 MATLAB 再打开。

== 跳过搜索

若搜索失败但您已知 Bridge 地址，请在 `yunlink.env` 中写明：

```
YUNLINK_ADDRESS=192.168.1.5:9696
```

请将 `YUNLINK_ADDRESS=` 设为 `ex01` 打印的「连接地址」。随后可运行 `ex02_connect_and_inspect`。

== 与地面站同时在线

YunLink 允许多个会话订阅同一批实体的遥测。地面站已经连接两架无人机与两辆无人车并实施控制时，MATLAB 仍可 `yunlink_connect`、`yunlink_vehicle` / `yunlink_ugv` 并调用 `yunlink_state`。只读路径不申请控制权。

一旦运行 `yunlink_takeoff`、`yunlink_translate`、`yunlink_ugv_move_to` 等函数，才会发送控制。现场全量检查 `ex12` 在桌面环境下会先确认，默认选项为「继续飞」。

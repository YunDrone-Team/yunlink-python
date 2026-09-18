#import "../vendor/mantys/src/mantys.typ": *

= 故障排除

本章按现象列出原因与处理步骤。处理时请先阅读命令窗口的完整报错，再对照本节。

== Add-On Explorer 搜索不到工具箱

现象：在 MATLAB 附加功能中搜索 YunLink 无结果。

原因：本工具箱不在 MathWorks 商店中。

处理：双击本地 `.mltbx`，或使用 `matlab.addons.install`。

== 提示需要支持的 CPython 版本，或出现 cp314

现象：`ex00_setup` 或 `pyenv` 报错，提到 3.14 或不受支持的版本。

原因：当前解释器版本与该 MATLAB 官方支持的 CPython 3.10–3.13 不一致。

处理：按第 2 章的对照表安装 Python，填写 `pythonExe`，*关闭 MATLAB 后重新打开*，再运行 `ex00_setup`。

== PythonAlreadyLoaded

现象：无法切换到新的 Python。

原因：本次 MATLAB 进程已经加载过另一个解释器。

处理：退出 MATLAB，重新启动，立即运行 `ex00_setup`。

== 无法导入 yunlink 或 yunlink_python

现象：`ModuleNotFoundError`。

原因：未运行 `ex00_setup`，或 `bundleDir` 未指向含有 `wheels` 的解压目录。覆盖安装工具箱后若未再次运行 `ex00_setup`，仍会加载旧轮子。

处理：使用当前 zip 的解压目录重新运行 `ex00_setup`。

== 搜索不到 Bridge

现象：`ex01_discover` 报没有搜索到 Bridge。

处理：

+ 确认仿真或机载 Bridge 已启动。
+ Windows 上允许 MATLAB 与 `python.exe` 通过专用网络访问。
+ 将 `ex01` 曾经打印过的地址写入 `YUNLINK_ADDRESS=`，跳过搜索。

== WinError 10054

现象：`discovery` 或 `ex01_discover` 出现「远程主机强迫关闭了一个现有的连接」。

原因：Windows 将 UDP 探测的 ICMP 不可达表现为套接字重置。

处理：安装当前发布包中的 SDK 后，该错误应被忽略。请重新 `ex00_setup` 并重启 MATLAB。若仍出现，请写死 `YUNLINK_ADDRESS=` 后从 `ex02` 继续。

== 连接超时或 YUNLINK_V2_ERROR(7)

现象：`yunlink_connect` 失败。

原因：`YUNLINK_ADDRESS` 与现场 Bridge 不一致，或 TCP 9696 不可达。请使用 `ex01` 打印的连接地址。

处理：使用 `ex01` 打印的「连接地址」。

== 实体未找到

现象：`EntityNotFoundError`，或提示找不到 UAV。

原因：`YUNLINK_UAV=` 填写了显示名 `uav1`，或填入了其他 Bridge 上的标识。

处理：从 `ex02` 表格的第一列复制 `entity_uid`。

== 起飞被拒绝（INIT）

现象：已在空中时调用 `yunlink_takeoff` 失败。

处理：示例在 `landed` 为真时才起飞。请先降落，或跳过起飞。

== 遥测不新鲜

现象：`fresh` 为 0。

处理：确认 attach 的 `entity_uid` 正确，等待数秒后再读。`frame_id` 为空时不要发送点位指令。

== 租约结束显示 CANCELLED

现象：`yunlink_translate` 或无人车速度指令返回 `CANCELLED`。

原因：短时租约到期。这是预期结果，不表示失败。

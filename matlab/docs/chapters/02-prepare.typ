#import "../vendor/mantys/src/mantys.typ": *

= 准备 MATLAB 与 Python

本工具箱不在 MATLAB 内部编译通信库，而是调用本机已安装的 CPython。因此须同时满足：MATLAB R2022b 或更新版本，以及该 MATLAB 官方支持的 CPython 3.10、3.11、3.12 或 3.13。

== 安装并启动 MATLAB

若本机尚未安装 MATLAB，请向实验室或学校申请许可证，并安装 *R2022b 或更新* 版本。R2022a 官方仅支持 Python 3.8/3.9，与本工具箱所需的通信库不匹配，无法使用。

启动方式：

- *Windows*：打开「开始」菜单，搜索 `MATLAB`，选择已安装的版本（例如 MATLAB R2026a）。
- *macOS*：打开「应用程序」，双击 MATLAB 图标。
- *Linux*：在终端输入 `matlab` 后回车。若命令未找到，请使用安装目录中的可执行文件，例如 `/usr/local/MATLAB/R2024b/bin/matlab`。

启动完成后，屏幕中央通常为编辑器，下方为*命令窗口*（Command Window），左侧为*当前文件夹*（Current Folder）。若未看到命令窗口，请在菜单栏选择「主页」，在「布局」或「环境」区域打开「命令窗口」。

== 命令窗口的用法

命令窗口是向 MATLAB 下达指令的地方，作用相当于交互式终端。

+ 用鼠标单击命令窗口内部，使光标出现在 `>>` 提示符后。
+ 使用键盘输入命令，例如 `pwd`，然后按 Enter（回车）。
+ MATLAB 会立即执行该行并打印结果。`pwd` 会显示当前文件夹的完整路径。

#info-alert[
  在命令窗口执行脚本时输入函数名，例如 `ex01_discover`。MATLAB 按函数名解析，文件后缀 `.m` 不必写出。
]

常用界面元素：

#figure(
  table(
    columns: (auto, 1fr),
    align: (left, left),
    stroke: 0.4pt,
    inset: 6pt,
    [*名称*], [*作用*],
    [命令窗口 Command Window], [输入命令并查看打印输出。],
    [当前文件夹 Current Folder], [列出当前目录中的文件。运行示例前，该目录须为 `examples`。],
    [编辑器 Editor], [打开 `.m` 文件阅读与修改。],
    [绿色「运行」或 F5], [执行编辑器中的当前脚本。],
    [红色「停止」或 Ctrl-C], [中断正在运行的脚本。],
  ),
  caption: [MATLAB 桌面中与本教程相关的区域],
)

请在命令窗口依次输入下列命令，确认界面可用：

```matlab
ver
pwd
```

`ver` 会列出 MATLAB 版本。请确认版本号为 R2022b 或更新。

== 为何需要本机 Python

MATLAB 通过官方的 CPython 接口调用 YunLink。发布包内含预编译的 `yunlink` 原生绑定与 `yunlink_python` SDK，由 `ex00_setup` 安装到您指定的 Python 中。MATLAB 自带的 Python 3.14 *不能*用于本工具箱。

请按下表选择解释器。表中未列出的组合会被 MATLAB 拒绝，并出现「Python 命令需要支持的 CPython 版本」。

#figure(
  table(
    columns: (auto, 1fr),
    align: (left, left),
    stroke: 0.4pt,
    inset: 6pt,
    [*MATLAB 版本*], [*本工具箱可用的 Python*],
    [R2022a], [不可用（官方仅 3.8/3.9）],
    [R2022b / R2023a], [3.10],
    [R2023b / R2024a], [3.10、3.11],
    [R2024b / R2025a], [3.10、3.11、3.12],
    [R2025b / R2026a], [3.10、3.11、3.12、3.13],
  ),
  caption: [MATLAB 与 CPython 版本对应关系],
)

== 安装 Python 并确认可执行文件

`ex00_setup` 与 `pyenv` 需要 Python *可执行文件*的完整路径，例如 Windows 上的 `python.exe`，或 macOS / Linux 上 `which python3.13` 打印的路径。

=== Windows

建议从 Python 官网安装 64 位安装包，并勾选 “Add python.exe to PATH”。安装完成后，在「命令提示符」或 PowerShell 中执行：

```text
python --version
where python
```

典型路径：

```text
C:\Users\<用户名>\AppData\Local\Programs\Python\Python313\python.exe
```

请将 `<用户名>` 替换为您的 Windows 账户名。若 `python --version` 显示 3.14，请改用带版本号的安装目录，例如 `Python313\python.exe`。

=== macOS

建议使用 Homebrew 安装：

```bash
brew install python@3.13
which python3.13
python3.13 --version
```

典型路径为 `/opt/homebrew/bin/python3.13`（Apple Silicon）或 `/usr/local/bin/python3.13`（Intel）。

=== Linux

```bash
python3 --version
which python3
```

若系统默认版本在 3.10–3.13 之外，请安装发行版软件包或使用 `python3.12` 等带版本号的命令。典型路径为 `/usr/bin/python3.12`。

#warning-alert[
  请在系统终端确认版本后，将该解释器路径填写到 MATLAB。请使用系统安装的 CPython 3.10–3.13。
]

#import "../vendor/mantys/src/mantys.typ": *

= 获取与安装工具箱

== 下载发布包

请使用浏览器打开下列地址，下载当前用户包：

#link("https://github.com/YunDrone-Team/yunlink-python/releases/download/matlab-1.4.5/yunlink-sunray-matlab-1.4.5-bundle.zip")[yunlink-sunray-matlab-1.4.5-bundle.zip]

不必克隆源代码仓库。本仓库的 GitHub Release 仅用于 MATLAB 用户包。

将 zip 解压到本地目录，例如 Windows 的「下载」文件夹。请在解压后的目录中双击 `.mltbx`。若解压后出现两层同名目录，请进入内层，直到同时看到 `.mltbx` 与 `wheels` 文件夹。

解压后通常包含：

- `yunlink-sunray-matlab-1.4.5.mltbx`：MATLAB 工具箱安装器。
- `wheels/`：按操作系统与 Python 版本提供的 `yunlink` 原生绑定。
- `yunlink_python-1.3.0-py3-none-any.whl`：MATLAB 调用的 Python SDK。
- `INSTALL.txt`、`README.md`：简要说明。
- 若存在 `yunlink-matlab-manual.pdf`，即为本文的编译版本。

== 安装 .mltbx

本工具箱通过本地 `.mltbx` 安装。Add-On Explorer 检索 MathWorks 商店，其中不含本工具箱。安装入口为双击 `.mltbx`，或使用下面的 `matlab.addons.install`。

+ 在资源管理器、Finder 或文件管理器中双击 `yunlink-sunray-matlab-1.4.5.mltbx`。
+ MATLAB 将打开 Toolbox 安装器。请确认名称为 *YunLink Sunray MATLAB Support*，然后点击 Install。
+ 若双击未能唤起 MATLAB，请先启动 MATLAB，在命令窗口执行：

```matlab
matlab.addons.install("完整路径/yunlink-sunray-matlab-1.4.5.mltbx")
```

请将引号中的路径替换为本机实际路径。Windows 使用反斜杠或正斜杠均可。

多次覆盖安装时，MATLAB 可能将工具箱目录命名为 `YunLink Sunray MATLAB Support(5)` 等形式。这不影响使用。示例目录以 `yunlink_examples` 切换后的路径为准。

#success-alert[
  安装完成后，命令窗口应能识别 `yunlink_examples`。若提示无法找到函数，请关闭 MATLAB 后重新打开。
]

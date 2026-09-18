#import "../vendor/mantys/src/mantys.typ": *

= 首次配置

安装工具箱只是把 MATLAB 函数放到路径上。通信库仍须装进本机 Python。这一步由 `ex00_setup` 完成，且*不连接飞机*。

== 打开示例目录

在命令窗口输入下列命令后回车：

```matlab
yunlink_examples
```

MATLAB 将：

- 把当前文件夹切换到工具箱的 `examples` 目录；
- 在桌面版打开当前文件夹浏览器；
- 尝试在编辑器中打开 `ex00_setup.m`。

命令窗口会打印脚本列表。该列表即为教程目录。请按 `ex00`、`ex01`、…、`ex12` 的顺序进行。

== 填写并运行 ex00_setup

在编辑器中打开 `ex00_setup.m`（若尚未自动打开，请在左侧当前文件夹中双击该文件）。文件开头有两个变量：

- `pythonExe`：Python 3.10–3.13 可执行文件的完整路径。可留空，脚本会按常见位置猜测。
- `bundleDir`：刚才解压的发布包目录。该目录中应能看到 `.mltbx` 与 `wheels`。可留空，脚本会在「下载」目录中查找。

建议首次使用时显式填写，以免猜错版本。填写后点击编辑器工具栏的绿色「运行」，或按 F5。

脚本将把匹配当前系统与 Python 版本的 wheel 解压进该解释器，并记住路径供下次启动。过程*不使用 pip*。

完成后请执行：

```matlab
pyenv
```

`Version` 字段须为 3.10、3.11、3.12 或 3.13。若 MATLAB 已经加载了其他 Python，请*关闭 MATLAB 后重新打开*，再运行一次 `ex00_setup`。

== 编写 yunlink.env

示例脚本不在中间改地址。目标写在 `examples` 目录的配置文件中。读取顺序为：

+ 操作系统环境变量中的同名键（若存在，优先生效）；
+ `yunlink.env`；
+ 若没有 `yunlink.env`，则读取 `yunlink.env.example`；
+ 若二者皆无，则报错 `yunlink:MissingEnv`。

您可以直接复制 `yunlink.env.example` 为 `yunlink.env`，也可以在没有 `yunlink.env` 时编辑 `yunlink.env.example`。

常用键：

- `YUNLINK_ADDRESS=`：Bridge 的 TCP 地址，格式为 `ip:9696`。留空则在仅发现一台 Bridge 时自动采用。
- `YUNLINK_BRIDGE_ID=`：多台 Bridge 时填写 `ex01` 打印的 Bridge ID（`endpoint_uid` 短字符串）。
- `YUNLINK_UAV=`、`YUNLINK_UGV=`：填写 `entity_uid`，例如 `e-f97f96-2-1`。
- `YUNLINK_DISCOVER_TIMEOUT=`：搜索秒数，默认 5。

请先运行 `ex01_discover`，再把打印结果填入上述键。

#info-alert[
  `yunlink_connect` 只建立与 Bridge 的会话，不会选中任何设备。`yunlink_vehicle` 或 `yunlink_ugv` 才会 attach。地面站已经连接并控制设备时，MATLAB 仍可只读遥测。
]

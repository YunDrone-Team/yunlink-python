#import "../vendor/mantys/src/mantys.typ": *

= 附录

== 发布包

当前用户包版本为 MATLAB *1.4.5*。下载地址：

#link("https://github.com/YunDrone-Team/yunlink-python/releases/download/matlab-1.4.5/yunlink-sunray-matlab-1.4.5-bundle.zip")[yunlink-sunray-matlab-1.4.5-bundle.zip]

更新时请重新安装 `.mltbx`，并再次运行 `ex00_setup`，将 `bundleDir` 指向新的解压目录。

== 端口

#figure(
  table(
    columns: (auto, auto, 1fr),
    align: (left, left, left),
    stroke: 0.4pt,
    inset: 6pt,
    [*端口*], [*协议*], [*用途*],
    [9697], [UDP], [搜索：本机查询，Bridge 回答],
    [9696], [TCP], [会话：连接、目录、遥测与控制],
  ),
  caption: [YunLink Bridge 默认端口],
)

== 支持的平台

Windows 64 位、macOS Apple Silicon、Linux x86_64。Python 须为 3.10–3.13 的官方 CPython，并与 MATLAB 版本匹配。

== 许可证

源代码以 Apache License 2.0 许可。版权所有 YunDrone Team。

本文使用 Typst 模板 mantys（MIT）排版。为兼容 Typst 0.15，文档目录内含经符号替换的 mantys 1.0.2 副本，仅用于编译本手册。

== 相关文件

- 工具箱内 `examples/README.md`：示例总表与第一次运行步骤。
- 工具箱内 `README.md`：安装与函数一览。
- `developer/API.md`：面向维护者的封装说明。

请以示例脚本中的注释与本文第 6、8 章为准。若二者冲突，以已安装工具箱中的 `.m` 文件行为为准。

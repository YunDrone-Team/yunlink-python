# YunLink MATLAB 使用指南（Typst）

这是逐步说明书的源码，从安装 MATLAB、打开命令窗口，讲到按编号运行 example 与查阅封装接口。

日常入门请先运行 `examples/` 中的脚本，接口说明见 [`../developer/API.md`](../developer/API.md)。本文供需要更细步骤时编译阅读。

仓库**不存放**编译后的 PDF。GitHub Release `matlab-1.4.5` 提供 `yunlink-matlab-manual.pdf`。本机编译：

```bash
typst compile matlab/docs/yunlink-matlab-manual.typ matlab/docs/yunlink-matlab-manual.pdf
```

须安装 [Typst](https://typst.app/) 0.13 或更新版本，并安装 **Noto Sans CJK SC** / **Noto Sans Mono CJK SC**。本仓库当前使用 Typst 0.15。

排版使用 mantys 1.0.2 的本地副本（`vendor/mantys`），以兼容 Typst 0.15（上游 1.0.2 的 `sym.angle.l` 在 0.15 中已移除，本地改为 `sym.chevron.l`）。代码清单使用 [zebraw](https://typst.app/universe/package/zebraw)，品牌色为 `#305693`。封面 logo 为 `assets/logo.svg`。

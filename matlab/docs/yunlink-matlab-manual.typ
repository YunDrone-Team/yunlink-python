#import "vendor/mantys/src/mantys.typ": *
#import "vendor/mantys/src/themes/default.typ": default
#import "@preview/zebraw:0.6.3": *

#let brand = rgb("#305693")
#let brand-soft = rgb("#4a7ab5")
#let noto = ("Noto Sans CJK SC",)
#let noto-mono = ("Noto Sans Mono CJK SC",)

#let yun-title-page(doc, theme) = {
  set align(center)
  set text(font: noto)
  set block(spacing: 1.35em)
  v(1.2cm)
  image("assets/logo.svg", width: 8.6cm)
  v(0.85cm)
  // 小于 mantys 默认 40pt，保证「YunLink MATLAB 使用指南」单行排下。
  block(
    text(
      size: 22pt,
      weight: "medium",
      fill: theme.primary,
      tracking: 0.4pt,
    )[#box(doc.title)],
  )
  if doc.subtitle != none {
    block(above: 0.6em, text(size: 13pt, fill: rgb(35, 31, 32), doc.subtitle))
  }
  text(size: 11pt)[v#doc.package.version]
  if doc.date != none {
    h(3em)
    text(size: 11pt, doc.date.display())
  }
  h(3em)
  text(size: 11pt, doc.package.license)
  if doc.package.description != none {
    block(above: 1.2em, text(size: 11pt, doc.package.description))
  }
  block(above: 1.1em, text(size: 11pt, smallcaps(doc.package.authors.map(a => a.name).join(", "))))
  if doc.urls != none {
    block(doc.urls.map(l => link(l)).join(linebreak()))
  }
  if doc.abstract != none {
    pad(x: 10%, {
      set align(left)
      set text(size: 10.5pt)
      doc.abstract
    })
  }
  if doc.show-outline {
    set align(left)
    set block(spacing: 0.65em)
    show outline.entry.where(level: 1): it => {
      v(0.85em, weak: true)
      strong(link(it.element.location(), it.inner()))
    }
    v(0.8cm)
    text(font: noto, weight: "bold", size: 1.25em, fill: brand)[目录]
    v(0.4em)
    columns(
      2,
      outline(title: none, indent: 1em, depth: 3),
    )
  }
  pagebreak()
}

#let yun-page-init(doc, theme) = (
  body => {
    show: (default.page-init)(doc, theme)
    set text(font: noto)
    set par(justify: false)
    show heading: set text(font: noto, fill: brand)
    show raw: set text(font: noto-mono, size: 9pt)
    show: zebraw-init.with(
      lang: true,
      numbering: true,
      numbering-separator: true,
      background-color: luma(250),
      lang-color: brand,
      highlight-color: brand.lighten(82%),
      radius: 4pt,
      inset: (top: 3pt, bottom: 3pt, right: 6pt, left: 6pt),
      lang-font-args: (font: noto, fill: white, size: 0.75em, weight: "bold"),
      numbering-font-args: (font: noto-mono, fill: brand.lighten(20%), size: 0.8em),
    )
    show: zebraw
    show raw.where(block: true): it => {
      block(
        width: 100%,
        stroke: 0.8pt + brand.lighten(35%),
        radius: 4pt,
        clip: true,
        breakable: true,
        it,
      )
    }
    show raw.where(block: false): it => box(
      fill: brand.lighten(92%),
      inset: (x: 4pt, y: 0pt),
      outset: (y: 3pt),
      radius: 2pt,
      it,
    )
    body
  }
)

#let yun-theme = create-theme(
  primary: brand,
  secondary: brand-soft,
  fonts: (
    serif: noto,
    sans: noto,
    mono: noto-mono,
  ),
  text: (
    size: 11pt,
    font: noto,
    fill: rgb(35, 31, 32),
  ),
  heading: (
    font: noto,
    fill: brand,
  ),
  header: (
    size: 10pt,
    fill: brand,
    font: noto,
  ),
  footer: (
    size: 9pt,
    fill: luma(120),
    font: noto,
  ),
  code: (
    size: 9pt,
    font: noto-mono,
    fill: rgb("#333333"),
  ),
  emph: (
    link: brand,
    package: brand,
  ),
  commands: (
    argument: brand,
    command: brand,
    variable: rgb("#5b3d8c"),
    builtin: brand-soft,
    comment: luma(120),
    symbol: rgb(35, 31, 32),
  ),
  title-page: yun-title-page,
  page-init: yun-page-init,
)

#show: mantys(
  name: "yunlink-sunray-matlab",
  title: [YunLink MATLAB 使用指南],
  subtitle: [安装、示例与接口说明],
  description: "YunLink Sunray MATLAB Support 的安装、示例与接口说明。",
  authors: "YunDrone Team",
  url: "https://github.com/YunDrone-Team/yunlink-python",
  version: "1.4.5",
  date: datetime(year: 2026, month: 9, day: 17),
  license: "Apache-2.0",
  abstract: [
    本文说明如何在 Windows、macOS 与 Linux 上准备 MATLAB 与 Python，如何获取并安装 YunLink Sunray MATLAB Support，以及如何通过编号示例学习搜索、连接、遥测与控制。
    请按章节顺序阅读，并在 MATLAB 中同步执行对应步骤。
  ],
  show-index: false,
  theme: yun-theme,
)

#show heading.where(level: 1): it => {
  pagebreak(weak: true)
  it
}

#include "chapters/01-preface.typ"
#include "chapters/02-prepare.typ"
#include "chapters/03-install.typ"
#include "chapters/04-config.typ"
#include "chapters/05-network.typ"
#include "chapters/06-examples.typ"
#include "chapters/07-model.typ"
#include "chapters/08-api.typ"
#include "chapters/09-troubleshoot.typ"
#include "chapters/10-appendix.typ"

# MATLAB 开发说明

用户安装和使用见 [../README.md](../README.md)。本页只覆盖源码开发、CLI 测试、Toolbox 打包和发布。

## 环境

- MATLAB R2026a 或更新版本
- Python 3.10、3.11 或 3.12
- 已安装的 `yunlink` binding 和 `yunlink-python`

本机 MATLAB：

```bash
MATLAB=/Applications/MATLAB_R2026a.app/bin/matlab
cd /path/to/yunlink-python
```

不要把仓库内部路径写进用户文档。

## CLI 测试

包装层语法和路径检查，不连接设备：

```bash
"$MATLAB" -batch "run('matlab/tests/run_tests.m')"
```

显式安装依赖（无图形向导）：

```bash
"$MATLAB" -batch "addpath('matlab'); yunlink_setup('/path/to/python3.12','/path/to/yunlink_python-1.1.0-py3-none-any.whl','/path/to/yunlink-binding.whl')"
```

无桌面环境下不要调用无参数 `yunlink_setup`。

非 Planner 联通测试需要已经运行的 Bridge：

```bash
YUNLINK_ADDRESS=192.168.31.236:9696 \
YUNLINK_ENTITY=uav1 \
"$MATLAB" -batch "pyenv('Version','/path/to/python3.12'); addpath('matlab'); run('matlab/tests/home_connectivity.m')"
```

该脚本会读取状态、起飞、短时直接位置控制、悬停并降落。不要把它当作用户入门示例。

## 打包

先准备纯 Python SDK wheel：

```bash
python -m build
```

然后构建用户 Toolbox：

```bash
"$MATLAB" -batch "addpath('matlab'); build_toolbox"
```

或指定输出文件和 SDK wheel：

```bash
"$MATLAB" -batch "addpath('matlab'); build_toolbox('/tmp/yunlink-sunray-matlab-1.1.0.mltbx','dist/yunlink_python-1.1.0-py3-none-any.whl')"
```

`build_toolbox.m` 使用临时目录白名单，只打包：

- 公共 `yunlink_*.m`
- `README.md`
- `getting_started.html`
- `examples/*.m`
- 仓库 `LICENSE`
- `vendor/yunlink_python-*.whl`（如果找得到）

明确排除：

- `build_toolbox.m`
- `tests/`
- `developer/`
- CI 文件和缓存

检查包内容：

```bash
unzip -l dist/yunlink-sunray-matlab-1.1.0.mltbx
```

## 发布 bundle

用户安装入口是 `.mltbx`。平台相关 YunLink binding 作为独立 wheel 放进发布 zip，不要打进 Toolbox。

建议目录：

```text
yunlink-sunray-matlab-1.1.0-bundle/
  yunlink-sunray-matlab-1.1.0.mltbx
  INSTALL.txt
  yunlink_python-1.1.0-py3-none-any.whl
  yunlink-*-cp312-*.whl
```

可用：

```bash
"$MATLAB" -batch "addpath('matlab/developer'); build_release_bundle('dist/bundle','/path/to/binding-wheels')"
```

`INSTALL.txt` 只说明：安装 `.mltbx`，运行 `yunlink_setup`，选择 Python 和 binding。

## Toolbox 元数据

- 名称：YunLink Sunray MATLAB Support
- 版本：与 Python SDK 相同，当前 `1.1.0`
- 最低 MATLAB：R2026a
- Getting Started：`getting_started.m`（MATLAB 要求 `.m` 或 `.mlx`；同内容的 HTML 仍打进用户包）

`yunlink_sunray.prj` 只是源码身份清单，真正打包入口是 `matlab/build_toolbox.m`。

# MATLAB 开发说明

用户安装和使用见 [../README.md](../README.md)。封装函数调用见 [API.md](API.md)。本页只覆盖源码开发、打包和发布。

打包机用 MATLAB R2026a。用户最低 **R2022b**，Python 最低 **3.10**（yunlink 绑定要求）。

## 用户交付物

用户只下载 GitHub Release 里的一个 zip：

```text
yunlink-sunray-matlab-1.3.1-bundle.zip
```

发布地址：

https://github.com/YunDrone-Team/yunlink-python/releases/tag/matlab-1.3.1

zip 内包含 Toolbox、纯 Python SDK wheel、各平台 YunLink binding wheel 和安装说明。用户不需要克隆本仓库。

## 环境

- MATLAB R2026a 或更新版本
- Python 3.10、3.11、3.12 或 3.13
- `gh`，用于下载 YunLink binding wheel 并创建 Release

```bash
MATLAB=/Applications/MATLAB_R2026a.app/bin/matlab
cd /path/to/yunlink-python
```

## CLI 测试

```bash
"$MATLAB" -batch "run('matlab/tests/run_tests.m')"
```

无桌面环境不要调用无参数 `yunlink_setup`。显式安装：

```matlab
yunlink_setup("/path/to/python3.12", "/path/to/yunlink_python-1.3.0-py3-none-any.whl", "/path/to/yunlink-binding.whl")
```

非 Planner 联通测试：

```bash
YUNLINK_ADDRESS=192.168.31.236:9696 \
YUNLINK_ENTITY=uav1 \
"$MATLAB" -batch "pyenv('Version','/path/to/python3.12'); addpath('matlab'); run('matlab/tests/home_connectivity.m')"
```

## 打包并发布

在仓库根目录执行：

```bash
bash matlab/developer/package_release.sh
```

脚本会：

1. 构建纯 Python SDK wheel。
2. 构建 `.mltbx`。
3. 从 `YunDrone-Team/yunlink` 的 `v2.0.2` Release 下载各平台 binding wheel。
4. 生成 `dist/yunlink-sunray-matlab-1.3.1-bundle/` 和对应 zip。

不要把 `dist/`、wheel 或 zip 提交进 git。

GitHub Actions 工作流 `MATLAB Release` 会在 `main` 上的 MATLAB/SDK 变更后自动打包 `.mltbx` 和发布 zip，并更新 `matlab-1.3.1` Release。本仓库的 GitHub Release 只用于 MATLAB 用户包。

本地创建或覆盖 Release：

```bash
gh release upload matlab-1.3.1 \
  dist/yunlink-sunray-matlab-1.3.1-bundle.zip \
  --clobber
```

## Toolbox 白名单

`build_toolbox.m` 只打包：

- 公共 `yunlink_*.m`
- `README.md`
- `API.md`（由 `developer/API.md` 复制）
- `getting_started.m`
- `getting_started.html`
- `examples/*.m` 与 `examples/README.md`
- `LICENSE`
- `vendor/yunlink_python-*.whl`

排除 `build_toolbox.m`、`tests/`、`developer/`、CI 和缓存。

Getting Started 入口必须是 `.m` 或 `.mlx`。HTML 只作为用户可读副本打进包内。

"""搜索 YunLink Bridge，只读，不连接也不发送控制命令。"""

from __future__ import annotations

import argparse

from _session import discover_timeout, wait_for_bridges

from yunlink_python import print_discovered_bridges

parser = argparse.ArgumentParser(description="搜索局域网中的 YunLink Bridge")
parser.add_argument(
    "--timeout",
    type=float,
    default=discover_timeout(),
    help="监听秒数，默认 5；也可在 examples/yunlink.env 写 YUNLINK_DISCOVER_TIMEOUT",
)
args = parser.parse_args()
if args.timeout <= 0:
    raise SystemExit("--timeout 必须大于 0")

# discovery 会听满 timeout 秒，收集所有唯一 Bridge，听完再打印。不是搜到一台就立刻结束。
bridges = wait_for_bridges(args.timeout)
if not bridges:
    raise SystemExit(
        "没有搜索到 Bridge；请检查网络，或在 examples/yunlink.env 填写 YUNLINK_ADDRESS 后改跑 02_connect_and_inspect.py"
    )

# 探测候选 ID 与地面站相同：endpoint_uid@ip:tcp_port。
print_discovered_bridges(bridges)

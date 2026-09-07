"""演示连接失败、实体不存在、动作拒绝和超时的处理方式。"""

from __future__ import annotations

import argparse

from _session import add_connection_arguments, open_bridge, select_uav

from yunlink_python import (
    ActionFailedError,
    ConnectionError,
    EntityNotFoundError,
    TimeoutError,
)

parser = argparse.ArgumentParser(description="演示连接、实体选择和 Action 异常")
add_connection_arguments(parser)
args = parser.parse_args()

try:
    # 先验证一个不存在的实体，然后再使用明确的实体 ID 做超时测试。
    with open_bridge(args.address or "127.0.0.1:9696", auto_reconnect=False) as client:
        try:
            client.vehicle("does-not-exist")
        except EntityNotFoundError as exc:
            print("entity error:", exc)

        vehicle = select_uav(client, args.entity)
        try:
            vehicle.takeoff(height_m=1.0, timeout=0.001)
        except TimeoutError as exc:
            print("timeout:", exc)
        except ActionFailedError as exc:
            print("action rejected or failed:", exc.result_code, exc.detail)
except ConnectionError as exc:
    print("connection error:", exc)

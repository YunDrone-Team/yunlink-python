"""演示连接失败、实体不存在、动作拒绝和超时的处理方式。"""

from __future__ import annotations

import os

from yunlink_python import (
    ActionFailedError,
    ConnectionError,
    EntityNotFoundError,
    TimeoutError,
    connect,
)

try:
    address = os.getenv("YUNLINK_ADDRESS", "127.0.0.1:9696")
    with connect(address, auto_reconnect=False) as client:
        try:
            client.vehicle("does-not-exist")
        except EntityNotFoundError as exc:
            print("entity error:", exc)

        vehicle = client.vehicle(os.getenv("YUNLINK_VEHICLE", "uav1"))
        try:
            vehicle.takeoff(height_m=1.0, timeout=0.001)
        except TimeoutError as exc:
            print("timeout:", exc)
        except ActionFailedError as exc:
            print("action rejected or failed:", exc.result_code, exc.detail)
except ConnectionError as exc:
    print("connection error:", exc)

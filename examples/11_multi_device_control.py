"""并行控制多台 UAV/UGV；每个设备仍由独立对象负责。"""

from __future__ import annotations

import argparse
import concurrent.futures
import os

from yunlink_sunray import connect, discover_and_connect


def run_uav(uav, height: float, offset: float) -> tuple[str, str]:
    try:
        uav.takeoff(height_m=height, timeout=45)
        start = uav.state.position
        uav.move_to(start.x + offset, start.y, height, timeout=60)
        uav.hover(timeout=15)
        uav.land(timeout=45)
        return uav.uid, "ok"
    except Exception as exc:  # noqa: BLE001 - report each device independently
        try:
            uav.land(timeout=30)
        except Exception as cleanup_error:  # noqa: BLE001
            return uav.uid, f"failed: {exc}; cleanup land failed: {cleanup_error}"
        return uav.uid, f"failed: {exc}; cleanup land completed"


def run_ugv(ugv, offset: float) -> tuple[str, str]:
    try:
        start = ugv.state.position
        ugv.move_to(start.x + offset, start.y, timeout=45)
        ugv.hold(timeout=15)
        return ugv.uid, "ok"
    except Exception as exc:  # noqa: BLE001
        return ugv.uid, f"failed: {exc}"


parser = argparse.ArgumentParser(description="Run small independent actions on every discovered device")
parser.add_argument("--uav-height", type=float, default=0.8)
parser.add_argument("--uav-offset", type=float, default=0.2)
parser.add_argument("--ugv-offset", type=float, default=0.2)
args = parser.parse_args()

address = os.getenv("YUNLINK_ADDRESS")
client = connect(address) if address else discover_and_connect(timeout=1.5)
with client:
    uavs = [client.vehicle(item.uid) for item in client.vehicles()]
    ugvs = [client.ugv(item.uid) for item in client.ugvs()]
    if not uavs and not ugvs:
        raise SystemExit("没有发现 UAV 或 UGV")

    futures = []
    with concurrent.futures.ThreadPoolExecutor(max_workers=max(1, len(uavs) + len(ugvs))) as pool:
        futures.extend(pool.submit(run_uav, uav, args.uav_height, args.uav_offset * (index + 1))
                       for index, uav in enumerate(uavs))
        futures.extend(pool.submit(run_ugv, ugv, args.ugv_offset * (index + 1))
                       for index, ugv in enumerate(ugvs))
        for future in concurrent.futures.as_completed(futures):
            uid, result = future.result()
            print(f"{uid}: {result}")

    print("最终状态：")
    for device in [*uavs, *ugvs]:
        print(f"  {device.uid}: {device.state}")

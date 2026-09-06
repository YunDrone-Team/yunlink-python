"""并行控制多台 UAV/UGV；每个设备仍由独立对象负责。"""

from __future__ import annotations

import argparse
import concurrent.futures
import os
import time

from yunlink_sunray import connect, discover_and_connect


def wait_until_ready(device, timeout: float = 5.0) -> None:
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        state = device.state
        if state.is_fresh() and state.frame_id:
            return
        time.sleep(0.1)
    raise TimeoutError("fresh state with a coordinate frame was not observed")


def wait_until_landed(uav, timeout: float = 5.0) -> None:
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        state = uav.state
        if state.fresh and state.landed and not state.armed:
            return
        time.sleep(0.1)
    raise TimeoutError("land action succeeded but landed state was not observed")


def run_uav(uav, height: float, offset: float) -> tuple[str, str]:
    stage = "wait for state"
    try:
        wait_until_ready(uav)
        stage = "takeoff"
        uav.takeoff(height_m=height, timeout=45)
        start = uav.state.position
        stage = "move"
        uav.move_to(start.x + offset, start.y, height, timeout=60)
        stage = "hover"
        uav.hover(timeout=15)
        stage = "land"
        uav.land(timeout=45)
        stage = "wait for landed state"
        wait_until_landed(uav)
        return uav.uid, "ok"
    except Exception as exc:  # noqa: BLE001 - report each device independently
        try:
            uav.land(timeout=30)
        except Exception as cleanup_error:  # noqa: BLE001
            return uav.uid, f"{stage} failed: {exc}; cleanup land failed: {cleanup_error}"
        return uav.uid, f"{stage} failed: {exc}; cleanup land completed"


def run_ugv(ugv, offset: float) -> tuple[str, str]:
    stage = "wait for state"
    try:
        wait_until_ready(ugv)
        start = ugv.state.position
        stage = "move"
        ugv.move_to(start.x + offset, start.y, timeout=45)
        stage = "hold"
        ugv.hold(timeout=15)
        return ugv.uid, "ok"
    except Exception as exc:  # noqa: BLE001
        return ugv.uid, f"{stage} failed: {exc}"


parser = argparse.ArgumentParser(
    description="Run small independent actions on every discovered device"
)
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
        futures.extend(pool.submit(run_uav, uav, args.uav_height, args.uav_offset) for uav in uavs)
        futures.extend(pool.submit(run_ugv, ugv, args.ugv_offset) for ugv in ugvs)
        for future in concurrent.futures.as_completed(futures):
            uid, result = future.result()
            print(f"{uid}: {result}")

    print("最终状态：")
    for device in [*uavs, *ugvs]:
        print(f"  {device.uid}: {device.state}")

"""给每台 UAV 提交自己的小航线；不使用编队或集群 API。"""

from __future__ import annotations

import argparse
import concurrent.futures
import os
import time

from _session import print_device_catalog

from yunlink_python import Waypoint, connect, discover_and_connect


def wait_for_odometry(uav, timeout: float = 5.0) -> None:
    deadline = time.monotonic() + timeout
    while not uav.state.frame_id:
        if time.monotonic() >= deadline:
            raise RuntimeError("odometry frame was not received before timeout")
        time.sleep(0.1)


def run_route(uav, index: int, height: float) -> tuple[str, str]:
    try:
        # 为了让不同 Planner 实现下的示例行为一致，先明确等待起飞完成，
        # 再提交这台 UAV 自己的航线。
        uav.takeoff(height_m=height, timeout=45)
        wait_for_odometry(uav)
        start = uav.state.position
        points = [
            Waypoint(start.x + 0.15 * (index + 1), start.y, height),
            Waypoint(start.x + 0.15 * (index + 1), start.y + 0.15, height),
        ]
        handle = uav.waypoints(points, timeout=120, wait=False)
        result = handle.wait(120)
        return uav.uid, f"{result.phase.name}: {result.detail}"
    except Exception as exc:  # noqa: BLE001
        try:
            uav.cancel(timeout=15)
        except Exception as cleanup_error:  # noqa: BLE001
            return uav.uid, f"failed: {exc}; cleanup cancel failed: {cleanup_error}"
        return uav.uid, f"failed: {exc}; cleanup cancel completed"


parser = argparse.ArgumentParser(description="Run independent waypoint routes on all UAVs")
parser.add_argument("--height", type=float, default=0.8)
args = parser.parse_args()

address = os.getenv("YUNLINK_ADDRESS")
client = connect(address) if address else discover_and_connect(timeout=1.5)
with client:
    # 这里是有意遍历全部 UAV，不是默认选择第一台；每个 UID 都会先显示在目录中。
    print_device_catalog(client)
    uavs = [client.vehicle(item.uid) for item in client.vehicles()]
    if not uavs:
        raise SystemExit("没有发现 UAV")
    with concurrent.futures.ThreadPoolExecutor(max_workers=len(uavs)) as pool:
        jobs = [pool.submit(run_route, uav, index, args.height) for index, uav in enumerate(uavs)]
        for job in concurrent.futures.as_completed(jobs):
            uid, result = job.result()
            print(f"{uid}: {result}")
    for uav in uavs:
        if not uav.state.landed:
            try:
                print(f"{uav.uid} land: {uav.land(timeout=45)}")
            except Exception as exc:  # noqa: BLE001
                print(f"{uav.uid} land failed: {exc}")

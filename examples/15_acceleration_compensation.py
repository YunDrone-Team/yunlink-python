"""已在 HOVER/MOVE 的 UAV：短时叠加 NED 加速度，最后只撤掉补偿。"""

import argparse
import time

from _session import add_connection_arguments, open_bridge, select_uav

parser = argparse.ArgumentParser(description="NED 加速度补偿（不负责起飞/降落）")
add_connection_arguments(parser)
args = parser.parse_args()

with open_bridge(args.address) as client:
    uav = select_uav(client, args.entity)
    with uav.acceleration_compensation() as channel:
        for _ in range(100):
            channel.update(0.01, 0.0, 0.0)  # 每拍算法输出；m/s²，不含重力。
            time.sleep(0.01)
    print("补偿已取消，原运动参考继续运行")

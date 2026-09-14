"""只读观测：attach 后原地刷新打印状态，不申请控制权。

地面站可以同时控制同一架机。本脚本只 attach 和订阅遥测，不会起飞或发控制。
终端使用备用屏幕整页覆盖；重定向到文件时按帧追加。Ctrl-C 退出。
"""

from __future__ import annotations

import argparse
import os
import sys
import time
from collections.abc import Callable

from _session import add_connection_arguments, wait_for_bridges

from yunlink_python import (
    Client,
    EntityInfo,
    Ugv,
    Vehicle,
    connect,
    connect_discovered,
    run_with_status,
)
from yunlink_python.display import format_fields
from yunlink_python.state import Quaternion, UgvState, Vector3, VehicleState

ENTER_ALT = "\033[?1049h"
LEAVE_ALT = "\033[?1049l"
CLEAR = "\033[2J\033[H"
HIDE_CURSOR = "\033[?25l"
SHOW_CURSOR = "\033[?25h"


def _tty() -> bool:
    return sys.stdout.isatty() and os.environ.get("TERM") != "dumb"


def _fmt(value: object) -> str:
    if isinstance(value, bool):
        return "是" if value else "否"
    if isinstance(value, float):
        return f"{value:.3f}"
    if isinstance(value, Vector3):
        return f"x={value.x:.3f}  y={value.y:.3f}  z={value.z:.3f}"
    if isinstance(value, Quaternion):
        return f"x={value.x:.3f}  y={value.y:.3f}  z={value.z:.3f}  w={value.w:.3f}"
    if value is None:
        return ""
    if isinstance(value, tuple):
        return ", ".join(str(item) for item in value)
    return str(value)


def _has_content(value: object) -> bool:
    if value is None:
        return False
    if isinstance(value, str):
        return bool(value)
    if isinstance(value, tuple):
        return bool(value)
    if isinstance(value, Vector3):
        return True
    if isinstance(value, Quaternion):
        return True
    if isinstance(value, (int, float, bool)):
        return True
    return True


def _rows(pairs: list[tuple[str, object]]) -> list[tuple[str, str]]:
    rows = []
    for label, value in pairs:
        if not _has_content(value):
            continue
        rows.append((label, _fmt(value)))
    return rows


def _vehicle_rows(info: EntityInfo, state: VehicleState, updates: int) -> list[tuple[str, str]]:
    loc = state.localization
    planner = state.planner
    age = "-" if state.received_at <= 0 else f"{time.time() - state.received_at:.2f}s"
    return _rows(
        [
            ("设备 ID", info.uid),
            ("名称", info.name),
            ("类型", info.kind),
            ("遥测更新次数", updates),
            ("已连接", state.connected),
            ("数据新鲜", state.fresh),
            ("距上次更新", age),
            ("坐标系", state.frame_id),
            ("位置", state.position),
            ("速度", state.velocity),
            ("姿态四元数", state.attitude),
            ("角速度", state.angular_velocity),
            ("已解锁", state.armed),
            ("已落地", state.landed),
            ("降落中", state.landing),
            ("电池电量 %", state.battery_percent),
            ("电池电压 V", state.battery_voltage_v),
            ("控制模式", state.control_mode_name or state.control_mode),
            ("控制状态", state.control_state),
            ("运动模式", state.movement_mode),
            ("PX4 模式", state.px4_mode),
            ("手动接管", state.manual_override),
            ("控制器类型", state.controller_type),
            ("定位有效", loc.valid),
            ("定位源", loc.source),
            ("定位频率 Hz", loc.update_hz),
            ("定位信息", loc.message),
            ("规划主状态", planner.main_state),
            ("任务状态", planner.task_state),
            ("任务名", planner.task_name),
            (
                "当前航点",
                f"{planner.current_waypoint_index + 1}/{planner.total_waypoints}"
                if planner.total_waypoints
                else "",
            ),
            ("距目标 m", planner.distance_to_goal_m),
            ("停留剩余 s", planner.hold_remaining_s),
            ("失败原因", planner.failure_reason),
            *_attribute_pairs(info),
        ]
    )


def _ugv_rows(info: EntityInfo, state: UgvState, updates: int) -> list[tuple[str, str]]:
    age = "-" if state.received_at <= 0 else f"{time.time() - state.received_at:.2f}s"
    return _rows(
        [
            ("设备 ID", info.uid),
            ("名称", info.name),
            ("类型", info.kind),
            ("遥测更新次数", updates),
            ("已连接", state.connected),
            ("数据新鲜", state.is_fresh()),
            ("距上次更新", age),
            ("坐标系", state.frame_id),
            ("位置", state.position),
            ("速度", state.velocity),
            ("控制状态", state.control_state),
            ("规划状态", state.planner_state),
            *_attribute_pairs(info),
        ]
    )


def _attribute_pairs(info: EntityInfo) -> list[tuple[str, object]]:
    labels = {
        "hardware_id": "硬件 ID",
        "sunray.agent_type": "代理类型",
        "sunray.system_mode": "系统模式",
        "sunray.agent_name": "代理名",
        "sunray.airframe_display_name": "机型",
        "sunray.agent_serial_number": "序列号",
    }
    pairs = []
    for key, label in labels.items():
        value = info.attributes.get(key, "")
        if value:
            pairs.append((label, value))
    return pairs


def _select_infos(client: Client, requested: str | None) -> list[EntityInfo]:
    catalog = [item for item in client.entities() if item.kind in {"sunray.uav", "sunray.ugv"}]
    if requested:
        matches = [item for item in catalog if item.uid == requested or item.name == requested]
        if not matches:
            raise SystemExit(f"目录中没有这个设备：{requested}")
        return matches
    if not catalog:
        raise SystemExit("Bridge 目录里没有 UAV/UGV。")
    return catalog


def _open_client(address: str | None) -> Client:
    if address:
        return run_with_status(f"正在连接 {address}", lambda: connect(address))
    bridges = wait_for_bridges()
    if not bridges:
        raise SystemExit("没有搜索到 Bridge；请在 examples/yunlink.env 填写 YUNLINK_ADDRESS。")
    if len(bridges) > 1:
        raise SystemExit("搜索到多个 Bridge，请填写 YUNLINK_ADDRESS 或 YUNLINK_BRIDGE_ID。")
    selected = bridges[0]
    return run_with_status(
        f"正在连接 {selected.ip}:{selected.tcp_port}",
        lambda: connect_discovered(selected),
    )


def _track_updates(devices: dict[str, Vehicle | Ugv]) -> dict[str, int]:
    counts = {uid: 0 for uid in devices}

    def bump(uid: str) -> Callable[[object], None]:
        def _on_change(_state: object) -> None:
            counts[uid] += 1

        return _on_change

    for uid, device in devices.items():
        device.on_state_changed(bump(uid))
    return counts


def _frame(
    client: Client,
    infos: list[EntityInfo],
    devices: dict[str, Vehicle | Ugv],
    counts: dict[str, int],
    started: float,
    frames: int,
    hz: float,
) -> str:
    total = sum(counts.values())
    blocks = [
        "YunLink 只读观测    不控制、不申请权限，地面站可以同时控机",
        (
            f"Bridge {client.bridge_uid}  {client.bridge_address}    "
            f"刷新 {frames} 次    遥测 {total} 包    "
            f"{hz:g} Hz    已运行 {time.monotonic() - started:.1f}s    Ctrl-C 退出"
        ),
        "",
    ]
    for info in infos:
        device = devices[info.uid]
        state = device.state
        title = "无人机" if isinstance(device, Vehicle) else "无人车"
        blocks.append(f"{title}  {info.name}  {info.uid}  本机遥测 {counts[info.uid]} 包")
        if isinstance(state, VehicleState):
            rows = _vehicle_rows(info, state, counts[info.uid])
        else:
            rows = _ugv_rows(info, state, counts[info.uid])
        blocks.append(format_fields(rows, label_width=12))
        blocks.append("")
    return "\n".join(blocks).rstrip() + "\n"


def main() -> None:
    parser = argparse.ArgumentParser(description="Attach 后原地刷新打印只读状态，不发送控制动作。")
    parser.add_argument("--seconds", type=float, default=0.0, help="观测时长，0 表示一直跑")
    parser.add_argument("--hz", type=float, default=5.0, help="刷新频率")
    add_connection_arguments(parser)
    args = parser.parse_args()
    if args.hz <= 0:
        raise SystemExit("--hz 必须大于 0")

    live = _tty()
    with _open_client(args.address) as client:
        infos = _select_infos(client, args.entity)
        devices = {info.uid: client.entity(info.uid) for info in infos}
        counts = _track_updates(devices)
        started = time.monotonic()
        deadline = None if args.seconds <= 0 else started + args.seconds
        frames = 0
        if live:
            sys.stdout.write(ENTER_ALT + CLEAR + HIDE_CURSOR)
            sys.stdout.flush()
        try:
            while deadline is None or time.monotonic() < deadline:
                frames += 1
                text = _frame(client, infos, devices, counts, started, frames, args.hz)
                if live:
                    sys.stdout.write(CLEAR + text)
                else:
                    sys.stdout.write(text + "----\n")
                sys.stdout.flush()
                time.sleep(1.0 / args.hz)
        except KeyboardInterrupt:
            if not live:
                sys.stdout.write("\n")
        finally:
            if live:
                sys.stdout.write(SHOW_CURSOR + LEAVE_ALT)
                sys.stdout.flush()


if __name__ == "__main__":
    main()

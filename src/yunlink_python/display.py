"""Discovery and catalog printers.

Identity strings follow SunrayGCS:

- discovery candidate: ``endpoint_uid@ip:tcp_port``
- vehicle key: ``endpoint_uid::entity_uid``

Color is optional ANSI and only used on a real TTY. ``NO_COLOR`` disables it;
piped or captured output stays plain text.
"""

from __future__ import annotations

import os
import re
import shutil
import sys
import threading
import time
import unicodedata
from collections.abc import Callable, Iterable, Mapping, Sequence
from typing import Any, TextIO, TypeVar

T = TypeVar("T")

_ANSI_RE = re.compile(r"\x1b\[[0-9;]*m")
_SPINNER = "⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏"
_RESET = "\033[0m"
_BOLD = "\033[1m"
_DIM = "\033[2m"
_CYAN = "\033[36m"
_GREEN = "\033[32m"
_YELLOW = "\033[33m"

_ATTR_COLUMNS = (
    ("hardware_id", "hardware"),
    ("sunray.agent_type", "type"),
    ("sunray.system_mode", "mode"),
)


def discovery_id(endpoint_uid: str, ip: str, tcp_port: int) -> str:
    """GCS 探测列表里区分一台可连接 Bridge 的候选 ID。"""
    return f"{endpoint_uid}@{ip}:{tcp_port}"


def vehicle_key(endpoint_uid: str, entity_uid: str) -> str:
    """GCS 在多 Bridge 下路由一台设备的内部键。"""
    return f"{endpoint_uid}::{entity_uid}"


def run_with_status(message: str, action: Callable[[], T], *, file: TextIO | None = None) -> T:
    """Run a blocking action. On a TTY, show a spinner on stderr until it returns."""
    stream = file if file is not None else sys.stderr
    if not _status_enabled(stream):
        return action()
    stop = threading.Event()

    def paint() -> None:
        index = 0
        started = time.monotonic()
        while not stop.is_set():
            elapsed = time.monotonic() - started
            frame = _SPINNER[index % len(_SPINNER)]
            stream.write(f"\r{frame} {message}  {elapsed:0.1f}s")
            stream.flush()
            index += 1
            stop.wait(0.08)

    worker = threading.Thread(target=paint, name="yunlink-status", daemon=True)
    worker.start()
    try:
        return action()
    finally:
        stop.set()
        worker.join(timeout=0.5)
        stream.write("\r\033[K")
        stream.flush()


def _status_enabled(stream: TextIO) -> bool:
    if os.environ.get("TERM") == "dumb":
        return False
    return bool(hasattr(stream, "isatty") and stream.isatty())


def color_enabled(stream: TextIO | None = None) -> bool:
    if os.environ.get("NO_COLOR"):
        return False
    if os.environ.get("TERM") == "dumb":
        return False
    if os.environ.get("FORCE_COLOR"):
        return True
    target = stream if stream is not None else sys.stdout
    return bool(hasattr(target, "isatty") and target.isatty())


def format_table(
    rows: Sequence[Mapping[str, str]],
    columns: Sequence[tuple[str, str]],
) -> str:
    """Render an aligned table. ``columns`` is ``(key, header)``."""
    if not columns:
        return ""
    widths = []
    for key, header in columns:
        width = _display_width(header)
        for row in rows:
            width = max(width, _display_width(str(row.get(key, ""))))
        widths.append(width)
    lines = [_join_cells([header for _, header in columns], widths)]
    lines.append(_join_cells(["-" * width for width in widths], widths))
    for row in rows:
        lines.append(_join_cells([str(row.get(key, "")) for key, _ in columns], widths))
    return "\n".join(lines)


def format_fields(
    rows: Sequence[tuple[str, str]],
    *,
    width: int | None = None,
    label_width: int = 12,
) -> str:
    """Render a terminal-width-limited label/value list. Long values wrap."""
    columns = shutil.get_terminal_size((100, 24)).columns if width is None else width
    value_width = max(8, columns - label_width - 2)
    lines: list[str] = []
    for label, value in rows:
        parts = _wrap_display(str(value), value_width)
        for index, part in enumerate(parts):
            prefix = _pad(label, label_width) if index == 0 else " " * label_width
            lines.append(f"{prefix}  {part}")
    return "\n".join(lines)


def _wrap_display(text: str, width: int) -> list[str]:
    if width <= 0:
        return [text]
    lines: list[str] = []
    current = ""
    for char in text:
        if current and _display_width(current + char) > width:
            lines.append(current)
            current = char
        else:
            current += char
    if current:
        lines.append(current)
    return lines or [""]


def print_discovered_bridges(
    bridges: Sequence[Any],
    *,
    file: TextIO | None = None,
) -> None:
    """Print every discovered Bridge and its advertised entities."""
    stream = file if file is not None else sys.stdout
    color = color_enabled(stream)
    count = len(bridges)
    _write(stream, f"搜索到 {count} 个 Bridge")
    if not bridges:
        return
    summary_rows = []
    for bridge in bridges:
        entities = ", ".join(
            f"{_entity_name(item)} [{_entity_kind(item)}]" for item in getattr(bridge, "entities", ())
        )
        summary_rows.append(
            {
                "id": discovery_id(bridge.endpoint_uid, bridge.ip, bridge.tcp_port),
                "bridge": bridge.endpoint_uid,
                "address": f"{bridge.ip}:{bridge.tcp_port}",
                "name": getattr(bridge, "display_name", "") or "-",
                "devices": entities or "无设备",
            }
        )
    _write(stream, "")
    _write(stream, _style("探测候选 ID 与地面站相同：endpoint_uid@ip:tcp_port", _DIM, color))
    _write(
        stream,
        format_table(
            summary_rows,
            (
                ("id", "探测候选 ID"),
                ("bridge", "Bridge ID"),
                ("address", "地址"),
                ("name", "名称"),
                ("devices", "广播设备"),
            ),
        ),
    )
    for bridge in bridges:
        _write(stream, "")
        _print_bridge_block(bridge, stream=stream, color=color)


def print_entity_catalog(
    entities: Sequence[Any],
    *,
    bridge_uid: str = "",
    bridge_address: str = "",
    file: TextIO | None = None,
) -> None:
    """Print a connected Bridge directory as an aligned table."""
    stream = file if file is not None else sys.stdout
    color = color_enabled(stream)
    if bridge_uid or bridge_address:
        _write(stream, _style("已连接 Bridge", _BOLD, color))
        if bridge_uid and bridge_address:
            host, port = _split_address(bridge_address)
            candidate = discovery_id(bridge_uid, host, port)
            _write(stream, _kv("探测候选 ID", candidate, color, value_style=_BOLD + _CYAN))
        if bridge_uid:
            _write(stream, _kv("Bridge ID", bridge_uid, color))
        if bridge_address:
            _write(stream, _kv("地址", bridge_address, color))
        _write(stream, "")
    _write(stream, f"设备目录（共 {len(entities)} 个）")
    _write(stream, _entity_table(entities, bridge_uid, color))


def print_client_catalog(client: Any, *, file: TextIO | None = None) -> list[Any]:
    """Print the live directory of a connected Client and return it."""
    devices = list(client.entities())
    print_entity_catalog(
        devices,
        bridge_uid=getattr(client, "bridge_uid", "") or "",
        bridge_address=getattr(client, "bridge_address", "") or "",
        file=file,
    )
    return devices


def _print_bridge_block(bridge: Any, *, stream: TextIO, color: bool) -> None:
    candidate = discovery_id(bridge.endpoint_uid, bridge.ip, bridge.tcp_port)
    _write(stream, _style("Bridge", _BOLD, color))
    _write(stream, _kv("探测候选 ID", candidate, color, value_style=_BOLD + _CYAN))
    _write(stream, _kv("Bridge ID", bridge.endpoint_uid, color))
    _write(stream, _kv("地址", f"{bridge.ip}:{bridge.tcp_port}", color))
    name = getattr(bridge, "display_name", "") or "-"
    _write(stream, _kv("名称", name, color))
    profiles = _format_profiles(getattr(bridge, "profiles", ()))
    if profiles:
        _write(stream, _kv("Profile", profiles, color))
    entities = tuple(getattr(bridge, "entities", ()) or ())
    _write(stream, "")
    _write(stream, f"设备（{len(entities)}）")
    _write(stream, _entity_table(entities, bridge.endpoint_uid, color))


def _entity_table(entities: Sequence[Any], bridge_uid: str, color: bool) -> str:
    rows = []
    for item in entities:
        uid = _entity_uid(item)
        kind = _entity_kind(item)
        attrs = dict(getattr(item, "attributes", {}) or {})
        row = {
            "uid": uid,
            "name": _entity_name(item) or "-",
            "kind": kind or "-",
            "key": vehicle_key(bridge_uid, uid) if bridge_uid else "-",
        }
        for attr_key, column in _ATTR_COLUMNS:
            row[column] = attrs.get(attr_key) or "-"
        if color:
            row["kind"] = _style(row["kind"], _kind_style(kind), True)
        rows.append(row)
    return format_table(
        rows,
        (
            ("uid", "entity_uid"),
            ("name", "名称"),
            ("kind", "类型"),
            ("key", "GCS 键"),
            ("hardware", "hardware"),
            ("type", "type"),
            ("mode", "mode"),
        ),
    )


def _format_profiles(profiles: Iterable[Any]) -> str:
    labels = []
    for profile in profiles:
        profile_id = str(getattr(profile, "profile_id", profile))
        short = profile_id.rsplit(".", 1)[-1]
        major = getattr(profile, "major", None)
        minor = getattr(profile, "minor", None)
        if major is None:
            labels.append(short)
        else:
            labels.append(f"{short}@{major}.{minor if minor is not None else 0}")
    return ", ".join(labels)


def _entity_uid(item: Any) -> str:
    return str(getattr(item, "entity_uid", None) or getattr(item, "uid", "") or "")


def _entity_name(item: Any) -> str:
    return str(getattr(item, "display_name", None) or getattr(item, "name", "") or "")


def _entity_kind(item: Any) -> str:
    return str(getattr(item, "kind", "") or "")


def _kind_style(kind: str) -> str:
    if kind.endswith(".uav") or kind == "uav":
        return _GREEN
    if kind.endswith(".ugv") or kind == "ugv":
        return _YELLOW
    return _CYAN


def _kv(label: str, value: str, color: bool, *, value_style: str = _BOLD) -> str:
    padded = _pad(label, 12)
    return f"{_style(padded, _DIM, color)} {_style(value, value_style, color)}"


def _style(text: str, code: str, enabled: bool) -> str:
    if not enabled or not code:
        return text
    return f"{code}{text}{_RESET}"


def _write(stream: TextIO, text: str) -> None:
    print(text, file=stream)


def _split_address(address: str) -> tuple[str, int]:
    value = address.strip()
    if value.startswith("["):
        close = value.find("]")
        host = value[1:close]
        port = int(value[close + 2 :])
        return host, port
    host, raw_port = value.rsplit(":", 1)
    return host, int(raw_port)


def _join_cells(cells: Sequence[str], widths: Sequence[int]) -> str:
    return "  ".join(_pad(cell, width) for cell, width in zip(cells, widths, strict=True))


def _pad(text: str, width: int) -> str:
    extra = max(0, width - _display_width(text))
    return text + (" " * extra)


def _display_width(text: str) -> int:
    width = 0
    for char in _ANSI_RE.sub("", text):
        category = unicodedata.category(char)
        if category == "Mn":
            continue
        width += 2 if unicodedata.east_asian_width(char) in {"W", "F"} else 1
    return width

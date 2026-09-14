from io import StringIO
from types import SimpleNamespace

from yunlink_python.display import (
    color_enabled,
    discovery_id,
    format_table,
    print_client_catalog,
    print_discovered_bridges,
    print_entity_catalog,
    run_with_status,
    vehicle_key,
)


def test_discovery_id_matches_gcs_candidate_key():
    assert discovery_id("89c423", "192.168.10.10", 9696) == "89c423@192.168.10.10:9696"


def test_vehicle_key_matches_gcs_route_key():
    assert vehicle_key("89c423", "e-89c423-2-1") == "89c423::e-89c423-2-1"


def test_format_table_aligns_cjk_headers():
    text = format_table(
        [{"id": "89c423@192.168.10.10:9696", "name": "uav1"}],
        (("id", "探测候选 ID"), ("name", "名称")),
    )
    header, _rule, row = text.splitlines()
    assert _visual_index(header, "名称") == _visual_index(row, "uav1")
    assert _visual_index(header, "探测候选 ID") == _visual_index(row, "89c423@")


def _visual_index(line: str, token: str) -> int:
    from yunlink_python.display import _display_width

    return _display_width(line[: line.index(token)])


def test_format_table_aligns_columns():
    text = format_table(
        [{"id": "a", "name": "uav1"}, {"id": "bb", "name": "ugv1"}],
        (("id", "ID"), ("name", "NAME")),
    )
    lines = text.splitlines()
    assert lines[0].startswith("ID")
    assert "uav1" in lines[2]
    assert lines[2].index("uav1") == lines[3].index("ugv1")
    assert lines[1].index("-") == 0
    assert lines[1].count("  ") == lines[0].count("  ")


def test_color_disabled_when_no_color_set(monkeypatch):
    monkeypatch.setenv("NO_COLOR", "1")
    monkeypatch.setenv("FORCE_COLOR", "1")
    assert color_enabled() is False


def test_print_discovered_bridges_highlights_gcs_identity():
    stream = StringIO()
    bridges = [
        SimpleNamespace(
            endpoint_uid="89c423",
            display_name="sim-bridge",
            ip="192.168.10.10",
            tcp_port=9696,
            profiles=(
                SimpleNamespace(profile_id="org.yunlink.mobility", major=1, minor=0),
                SimpleNamespace(profile_id="com.yundrone.sunray", major=2, minor=8),
            ),
            entities=(
                SimpleNamespace(
                    entity_uid="e-89c423-2-1",
                    display_name="uav1",
                    kind="sunray.uav",
                    attributes={
                        "hardware_id": "SIM-UAV-001",
                        "sunray.agent_type": "simulation",
                        "sunray.system_mode": "sim",
                    },
                ),
                SimpleNamespace(
                    entity_uid="e-89c423-3-1",
                    display_name="ugv1",
                    kind="sunray.ugv",
                    attributes={"hardware_id": "SIM-UGV-001"},
                ),
            ),
        )
    ]
    print_discovered_bridges(bridges, file=stream)
    text = stream.getvalue()
    assert "89c423@192.168.10.10:9696" in text
    assert "89c423::e-89c423-2-1" in text
    assert "89c423::e-89c423-3-1" in text
    assert "e-89c423-2-1" in text
    assert "mobility@1.0" in text
    assert "sunray@2.8" in text
    assert "\033[" not in text
    assert "Profile(profile_id=" not in text


def test_print_entity_catalog_uses_connected_bridge_identity():
    stream = StringIO()
    print_entity_catalog(
        [
            SimpleNamespace(
                uid="e-89c423-2-1",
                name="uav1",
                kind="sunray.uav",
                attributes={"hardware_id": "SIM-UAV-001"},
            )
        ],
        bridge_uid="89c423",
        bridge_address="192.168.10.10:9696",
        file=stream,
    )
    text = stream.getvalue()
    assert "探测候选 ID" in text
    assert "89c423@192.168.10.10:9696" in text
    assert "89c423::e-89c423-2-1" in text


def test_print_client_catalog_reads_client_fields():
    stream = StringIO()
    client = SimpleNamespace(
        bridge_uid="bridge.fake",
        bridge_address="127.0.0.1:9696",
        entities=lambda: [
            SimpleNamespace(uid="uav1", name="uav1", kind="sunray.uav", attributes={})
        ],
    )
    devices = print_client_catalog(client, file=stream)
    assert [item.uid for item in devices] == ["uav1"]
    assert "bridge.fake@127.0.0.1:9696" in stream.getvalue()
    assert "bridge.fake::uav1" in stream.getvalue()


def test_run_with_status_without_tty_just_calls_action():
    calls = []

    def action():
        calls.append("ran")
        return 7

    assert run_with_status("working", action, file=StringIO()) == 7
    assert calls == ["ran"]

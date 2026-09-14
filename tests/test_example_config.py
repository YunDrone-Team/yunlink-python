import importlib.util
from pathlib import Path

_SESSION_PATH = Path(__file__).resolve().parents[1] / "examples" / "_session.py"


def _session():
    spec = importlib.util.spec_from_file_location("example_session", _SESSION_PATH)
    assert spec is not None and spec.loader is not None
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def test_parse_env_file_ignores_comments_and_blank_lines():
    text = """
# comment
YUNLINK_ADDRESS=192.168.10.10:9696

export YUNLINK_UAV=e-89c423-2-1
YUNLINK_UGV="ugv1"
EMPTY=
"""
    assert _session().parse_env_file(text) == {
        "YUNLINK_ADDRESS": "192.168.10.10:9696",
        "YUNLINK_UAV": "e-89c423-2-1",
        "YUNLINK_UGV": "ugv1",
        "EMPTY": "",
    }


def test_example_template_exists():
    example = Path(__file__).resolve().parents[1] / "examples" / "yunlink.env.example"
    text = example.read_text(encoding="utf-8")
    assert "YUNLINK_ADDRESS=" in text
    assert "YUNLINK_UAV=" in text
    assert "YUNLINK_UGV=" in text
    assert "YUNLINK_VEHICLE=" not in text
    assert "YUNLINK_ENTITY_ID=" not in text
    assert "YUNLINK_BRIDGE_ID=" in text
    assert "YUNLINK_DISCOVER_TIMEOUT=" in text

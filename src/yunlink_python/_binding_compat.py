"""Compatibility for YunLink wheels with protobuf files under profiles/org."""

from __future__ import annotations

import importlib
import sys
from pathlib import Path


def prepare_profile_imports() -> None:
    """Make generated absolute ``org.*`` imports visible when needed.

    Some YunLink 2.0.1 wheels keep generated ``org`` packages below
    ``yunlink/profiles`` while the generated protobuf imports them as top-level
    modules. A correctly packaged binding needs no path change; this fallback
    only exposes the existing package directory and does not load or copy code.
    """
    try:
        importlib.import_module("org.yunlink.mobility.v1")
        return
    except ModuleNotFoundError as error:
        if error.name != "org":
            raise

    import yunlink

    profiles_root = Path(yunlink.__file__).resolve().parent / "profiles"
    if profiles_root.is_dir() and str(profiles_root) not in sys.path:
        sys.path.insert(0, str(profiles_root))

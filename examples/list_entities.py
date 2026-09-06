"""Discover a Bridge and list its entities without sending flight commands."""

from yunlink_sunray import discover

for bridge in discover(timeout=1.0):
    print(f"{bridge.endpoint_uid}: {bridge.ip}:{bridge.tcp_port}")
    for entity in bridge.entities:
        print(f"  {entity.entity_uid} {entity.kind} {entity.display_name}")

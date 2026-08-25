"""Discover one SIM Bridge, then take off, move, and land."""

from yunlink_sunray import discover_and_connect

with discover_and_connect() as client:
    vehicle = client.vehicle()
    if vehicle.state.received_at:
        print("Initial state:", vehicle.state)
    vehicle.takeoff(1.5, timeout=30)
    vehicle.move_to(2.0, 0.0, 1.5, timeout=60)
    vehicle.land(timeout=30)

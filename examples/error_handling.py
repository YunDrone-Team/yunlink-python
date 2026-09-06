"""Keep action failures and timeouts visible to the caller."""

from yunlink_sunray import ActionFailedError, TimeoutError, connect

try:
    with connect("192.168.31.236:9696") as client:
        vehicle = client.vehicle("uav1")
        vehicle.takeoff(1.0, timeout=30)
        vehicle.move_to(0.4, 0.0, 1.0, timeout=60)
        vehicle.land(timeout=30)
except (ActionFailedError, TimeoutError) as exc:
    print(f"control failed: {exc}")

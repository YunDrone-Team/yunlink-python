"""Read state and inspect a non-blocking action handle."""

from yunlink_sunray import connect

with connect("192.168.31.236:9696") as client:
    vehicle = client.vehicle("uav1")
    print("state:", vehicle.state)
    handle = vehicle.takeoff(1.0, timeout=30, wait=False)
    print("phase:", handle.phase, "progress:", handle.progress)
    print("result:", handle.wait(30))
    print("state after takeoff:", vehicle.state)
    vehicle.land(timeout=30)

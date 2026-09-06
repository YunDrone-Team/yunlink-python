"""Run short forward/backward commands, then land."""

from yunlink_sunray import connect

with connect("192.168.31.236:9696") as client:
    vehicle = client.vehicle("uav1")
    vehicle.takeoff(1.0, timeout=30)
    vehicle.forward(speed_mps=0.15, duration_s=0.5)
    vehicle.backward(speed_mps=0.15, duration_s=0.5)
    vehicle.hover()
    vehicle.land(timeout=30)

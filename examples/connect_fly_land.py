"""Connect directly to a Bridge, then take off, move, and land."""

from yunlink_sunray import connect

with connect("192.168.31.236:9696") as client:
    vehicle = client.vehicle("uav1")
    vehicle.takeoff(1.5)
    vehicle.move_to(2.0, 0.0, 1.5)
    vehicle.land()

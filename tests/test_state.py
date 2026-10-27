from yunlink_python.state import LocalizationState, VehicleState


def test_localization_stale_clears_usable_frame():
    from types import SimpleNamespace

    from yunlink.profiles.com.yundrone.sunray.v2 import sunray_pb2

    from yunlink_python.state import StateStore
    from yunlink_python.vehicle import Vehicle

    vehicle = object.__new__(Vehicle)
    vehicle._state = StateStore()
    vehicle._state.update(frame_id="world")
    message = sunray_pb2.LocalizationState(status=sunray_pb2.LOCALIZATION_STALE, reason="stale")
    vehicle._on_localization(None, SimpleNamespace(data=message.SerializeToString()))
    assert vehicle.state.frame_id == ""
    assert not vehicle.state.localization.valid
    assert vehicle.state.localization.message == "stale"


def test_arm_and_landing_state_are_derived_without_control_methods():
    state = VehicleState(
        armed=True,
        landed=False,
        movement_mode="land",
        localization=LocalizationState(valid=True, source=5, update_hz=120),
    )
    assert not state.disarmed
    assert state.landing
    assert state.localization.update_hz == 120

    landed = VehicleState(armed=False, landed=True, movement_mode="land")
    assert landed.disarmed
    assert not landed.landing

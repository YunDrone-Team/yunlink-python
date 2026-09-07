from yunlink_python.state import LocalizationState, VehicleState


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

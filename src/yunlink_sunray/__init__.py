"""Simple Python control for Sunray vehicles through YunLink."""

from .actions import ActionHandle, ActionResult
from .client import (
    Client,
    EntityInfo,
    VehicleInfo,
    connect,
    connect_discovered,
    discover,
    discover_and_connect,
)
from .errors import (
    ActionFailedError,
    AuthorityError,
    ConnectionError,
    DisconnectedError,
    EntityNotFoundError,
    TimeoutError,
    YunLinkSunrayError,
)
from .profiles import Waypoint
from .state import PlannerState, UgvState, Vector3, VehicleState
from .ugv import Ugv
from .vehicle import Vehicle

__all__ = [
    "ActionFailedError",
    "ActionHandle",
    "ActionResult",
    "AuthorityError",
    "Client",
    "ConnectionError",
    "DisconnectedError",
    "EntityInfo",
    "EntityNotFoundError",
    "PlannerState",
    "TimeoutError",
    "Ugv",
    "UgvState",
    "Vector3",
    "Vehicle",
    "VehicleInfo",
    "VehicleState",
    "Waypoint",
    "YunLinkSunrayError",
    "connect",
    "connect_discovered",
    "discover",
    "discover_and_connect",
]

__version__ = "1.1.0"

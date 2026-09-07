"""Blocking action handle used by the simple vehicle API."""

from __future__ import annotations

import dataclasses
import threading
import time
from collections.abc import Callable

import yunlink

from .errors import ActionFailedError, DisconnectedError, TimeoutError


@dataclasses.dataclass(frozen=True)
class ActionResult:
    action_id: int
    phase: yunlink.ActionPhase
    result_code: int
    detail: str


class ActionHandle:
    def __init__(self, action_id: int, cancel: Callable[[], None]) -> None:
        self.action_id = action_id
        self._cancel = cancel
        self._condition = threading.Condition()
        self._update = yunlink.ActionUpdate(yunlink.ActionPhase.RECEIVED)
        self._error: Exception | None = None

    @property
    def phase(self) -> yunlink.ActionPhase:
        with self._condition:
            return self._update.phase

    @property
    def progress(self) -> int:
        with self._condition:
            return self._update.progress_percent

    @property
    def detail(self) -> str:
        with self._condition:
            return self._update.detail

    @property
    def done(self) -> bool:
        with self._condition:
            return self._error is not None or self._update.phase.terminal

    def cancel(self) -> None:
        if not self.done:
            self._cancel()

    def wait(self, timeout: float | None = None) -> ActionResult:
        deadline = None if timeout is None else time.monotonic() + timeout
        with self._condition:
            while not self.done:
                remaining = None if deadline is None else deadline - time.monotonic()
                if remaining is not None and remaining <= 0:
                    raise TimeoutError(f"action {self.action_id} timed out")
                self._condition.wait(remaining)
            if self._error is not None:
                raise self._error
            update = self._update
        if update.phase not in (yunlink.ActionPhase.SUCCEEDED, yunlink.ActionPhase.CANCELLED):
            raise ActionFailedError(update.result_code, update.detail)
        return ActionResult(self.action_id, update.phase, update.result_code, update.detail)

    def _set_update(self, update: yunlink.ActionUpdate) -> None:
        with self._condition:
            self._update = update
            self._condition.notify_all()

    def _set_disconnected(self) -> None:
        with self._condition:
            if not self._update.phase.terminal:
                self._error = DisconnectedError("connection was lost; the action was not replayed")
                self._condition.notify_all()

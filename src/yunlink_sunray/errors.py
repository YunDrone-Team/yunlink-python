"""Public SDK errors."""


class YunLinkSunrayError(RuntimeError):
    pass


class ConnectionError(YunLinkSunrayError):
    pass


class DisconnectedError(ConnectionError):
    pass


class TimeoutError(YunLinkSunrayError):
    pass


class EntityNotFoundError(YunLinkSunrayError):
    pass


class AuthorityError(YunLinkSunrayError):
    pass


class ActionFailedError(YunLinkSunrayError):
    def __init__(self, result_code: int, detail: str) -> None:
        self.result_code = result_code
        self.detail = detail
        super().__init__(detail or f"action failed with result code {result_code}")

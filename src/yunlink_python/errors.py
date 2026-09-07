"""Public SDK errors."""


class YunLinkPythonError(RuntimeError):
    pass


class ConnectionError(YunLinkPythonError):
    pass


class DisconnectedError(ConnectionError):
    pass


class TimeoutError(YunLinkPythonError):
    pass


class EntityNotFoundError(YunLinkPythonError):
    pass


class AuthorityError(YunLinkPythonError):
    pass


class ActionFailedError(YunLinkPythonError):
    def __init__(self, result_code: int, detail: str) -> None:
        self.result_code = result_code
        self.detail = detail
        super().__init__(detail or f"action failed with result code {result_code}")

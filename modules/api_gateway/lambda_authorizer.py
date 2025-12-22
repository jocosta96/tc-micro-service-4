import os


def lambda_handler(event, context):
    """
    Simple HTTP API Lambda authorizer.

    This implementation is adapted from the original TOKEN authorizer sample.
    It checks a shared TOKEN from environment variables against the
    Authorization header and returns an isAuthorized boolean, which matches
    the HTTP API Lambda authorizer simple response format (payload v2.0).
    """

    token = None
    headers = event.get("headers") or {}

    for key, value in headers.items():
        if key.lower() == "authorization":
            token = value
            break

    expected = os.environ.get("TOKEN")

    is_allowed = bool(token) and token == expected

    return {
        "isAuthorized": is_allowed,
        "context": {},
    }



#!/usr/bin/env python3
"""One matching rule for deciding whether a settings command invokes a telemetry unit.

Hook commands reach settings in two shapes. A bare invocation ends with its argument:

    bash ".../eos-telemetry-event.sh" pre_tool_use

A gate-wrapped invocation passes the argument after "--" and continues with shell text:

    SOFT=".../soft-hook-gate.sh"; if [ -r "$SOFT" ]; then bash "$SOFT" --event PreToolUse \\
      --unit ".../eos-telemetry-event.sh" -- pre_tool_use; else echo ...; exit 0; fi

A trailing-suffix test alone therefore reports every gate-wrapped hook as missing. This
module exists so the session guard's two checks cannot drift apart: a wrong verdict in
the boundary check blocks the session outright under a "required" telemetry policy.
"""
from __future__ import annotations

import re

__all__ = ["invokes"]


def invokes(command: str, unit: str, argument: str | None = None) -> bool:
    """Return True when `command` invokes `unit`, bare or through a hook gate.

    When `argument` is given it must appear as a whole word, so "stop" does not match
    "stop_failure".
    """

    if unit not in command:
        return False
    if argument is None:
        return True
    if command.rstrip().endswith(f" {argument}"):
        return True
    return bool(re.search(rf"--\s+{re.escape(argument)}(?![A-Za-z0-9_])", command))

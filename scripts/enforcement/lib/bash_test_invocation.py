#!/usr/bin/env python3
"""Classify what an observed Bash command actually executed from the test corpus.

The previous implementation matched `re.fullmatch` against the ENTIRE command, so it
recognised `bash scripts/enforcement/tests/test-x.sh` and nothing else. Any wrapper —
a `cd` prefix, an `&&` chain, a pipe, a redirect — changed the command text without
changing the work, and the suite ran with no runtime record. Virtually every real
invocation is wrapped, so the miss was the common case.

This scanner splits a command into shell control-operator segments (quote-aware) and
classifies each segment on its own. That recognises the wrappers, while keeping the
trust properties phase 1 established:

  * a *mention* of a suite path (`echo bash .../test-x.sh`, `grep test-x.sh`) is not
    an execution and is never classified;
  * a segment inside a command substitution is not classified: its output goes into a
    variable rather than to the tool boundary the recorder inspects, so the recorder
    cannot check it for failure;
  * `||` anywhere in the command marks every classification untrusted — the exit
    status of at least one member of that list is discarded, which is exactly how a
    failing suite is made to look successful;
  * a backgrounded segment (`&`) is untrusted — its output and status are not tied to
    the observed tool result;
  * a suite upstream of a pipe is `filtered` rather than trusted: a downstream stage
    can drop the very failure lines the recorder inspects, so the caller must demand a
    positive success signal instead of merely the absence of a failure one. Truncating
    the success line away then yields no record, which fails safe.

Redirections are not separators: `2>&1`, `>file`, `&>log` leave the classification
alone. A redirect that sends the suite's output to a file simply produces no observable
output, and the recorder already refuses to record from an empty tool result.

Output is one tab-separated record per detected execution, on stdout:

    direct-suite\t<path>\t<direct|filtered|untrusted>
    canonical-runner\t<path>\t<direct|filtered|untrusted>

`canonical-runner` is emitted for run-enforcement-tests.sh without `--fixture` (a
fixture run executes arbitrary scripts, not the corpus). Nothing is printed when the
command executed nothing from the corpus. Exit status is always 0: this is a
classifier, and an unclassifiable command simply produced no evidence.
"""
from __future__ import annotations

import re
import sys

SUITE_RE = re.compile(r"^(?:\./)?scripts/enforcement/tests/test-[A-Za-z0-9._-]+\.sh$")
RUNNER_RE = re.compile(r"^(?:\./)?scripts/enforcement/run-enforcement-tests\.sh$")
ASSIGNMENT_RE = re.compile(r"^[A-Za-z_][A-Za-z0-9_]*=")
INTERPRETERS = {"bash", "/bin/bash", "/usr/bin/bash", "sh", "/bin/sh", "env"}
REDIRECT_RE = re.compile(r"^\d*(?:>>|>&|<&|>|<)")

# Operators that separate one command from the next, longest first so "&&" is not
# read as "&" and "|&" is not read as "|".
OPERATORS = ("&&", "||", ";;", "|&", ";", "|", "&", "\n")
# `&` also appears inside redirections (`2>&1`, `<&3`, `&>log`, `&>>log`). Those are
# part of one command, not a separator, so they must never split a segment or be read
# as backgrounding.
REDIRECT_AMP_BEFORE = ("<", ">")


def split_segments(command: str) -> list[tuple[str, str, str]]:
    """Split into (text, operator-before, operator-after), skipping substitutions.

    Quote state is tracked so an operator inside '...' or "..." is literal text, and
    `$(...)`/backtick regions are dropped entirely: what runs inside a substitution
    does not reach the tool output boundary, so it cannot be verified.
    """
    segments: list[tuple[str, str, str]] = []
    buf: list[str] = []
    prev_op = ""
    quote = ""
    depth = 0
    index = 0
    length = len(command)

    while index < length:
        char = command[index]

        if quote:
            if quote == "'" and char == "'":
                quote = ""
            elif quote == '"' and char == "\\" and index + 1 < length:
                if depth == 0:
                    buf.append(command[index : index + 2])
                index += 2
                continue
            elif quote == '"' and char == '"':
                quote = ""
            if depth == 0:
                buf.append(char)
            index += 1
            continue

        if char == "\\" and index + 1 < length:
            # A backslash-newline is a line continuation, not a separator.
            if depth == 0 and command[index + 1] != "\n":
                buf.append(command[index : index + 2])
            index += 2
            continue

        if char in ("'", '"'):
            quote = char
            if depth == 0:
                buf.append(char)
            index += 1
            continue

        if command.startswith("$(", index):
            depth += 1
            index += 2
            continue
        if char == "`":
            # Backticks do not nest; toggle the opaque region.
            depth = 0 if depth else 1
            index += 1
            continue
        if char == ")" and depth:
            depth -= 1
            index += 1
            continue
        if depth:
            index += 1
            continue

        matched = next((op for op in OPERATORS if command.startswith(op, index)), None)
        if matched == "&":
            tail = "".join(buf).rstrip()
            # `2>&1` / `<&3`: the ampersand belongs to the redirection to its left.
            if tail.endswith(REDIRECT_AMP_BEFORE):
                buf.append(char)
                index += 1
                continue
            # `&>log` / `&>>log`: the ampersand belongs to the redirection to its right.
            if command.startswith("&>", index):
                buf.append(char)
                index += 1
                continue
        if matched:
            segments.append(("".join(buf), prev_op, matched))
            buf = []
            prev_op = matched
            index += len(matched)
            continue

        buf.append(char)
        index += 1

    segments.append(("".join(buf), prev_op, ""))
    return segments


def tokenize(segment: str) -> list[str]:
    """Split one segment into words, keeping quote state but dropping the quotes."""
    words: list[str] = []
    buf: list[str] = []
    quote = ""
    index = 0
    length = len(segment)
    while index < length:
        char = segment[index]
        if quote:
            if char == quote:
                quote = ""
            elif quote == '"' and char == "\\" and index + 1 < length:
                buf.append(segment[index + 1])
                index += 2
                continue
            else:
                buf.append(char)
            index += 1
            continue
        if char in ("'", '"'):
            quote = char
            index += 1
            continue
        if char == "\\" and index + 1 < length:
            buf.append(segment[index + 1])
            index += 2
            continue
        if char.isspace():
            if buf:
                words.append("".join(buf))
                buf = []
            index += 1
            continue
        buf.append(char)
        index += 1
    if buf:
        words.append("".join(buf))
    return words


def classify_segment(segment: str) -> tuple[str, str] | None:
    """Return (kind, path) when this segment executes something from the corpus."""
    words = tokenize(segment)
    index = 0
    # Leading environment assignments (FOO=bar cmd) do not change what is executed.
    while index < len(words) and ASSIGNMENT_RE.match(words[index]):
        index += 1
    # An interpreter prefix, optionally repeated (`env bash ...`), and its own flags.
    while index < len(words) and words[index] in INTERPRETERS:
        index += 1
        while index < len(words) and ASSIGNMENT_RE.match(words[index]):
            index += 1
        while index < len(words) and words[index].startswith("-") and words[index] != "--":
            index += 1
        if index < len(words) and words[index] == "--":
            index += 1
    if index >= len(words):
        return None
    target = words[index]
    rest = words[index + 1 :]
    if SUITE_RE.match(target):
        return ("direct-suite", target[2:] if target.startswith("./") else target)
    if RUNNER_RE.match(target):
        # A fixture run executes caller-supplied scripts, not the corpus, so it must
        # never be recorded as corpus evidence.
        if "--fixture" in rest:
            return None
        return ("canonical-runner", target)
    return None


def scan(command: str) -> list[tuple[str, str, str]]:
    segments = split_segments(command)
    # `||` discards the exit status of at least one list member. Rather than reason
    # about which side the suite is on, treat the whole command as untrusted: a real
    # verification run has no reason to mask a failure.
    masked = any(op == "||" for _, _, op in segments) or any(
        before == "||" for _, before, _ in segments
    )
    results: list[tuple[str, str, str]] = []
    for text, _before, after in segments:
        classified = classify_segment(text)
        if classified is None:
            continue
        kind, path = classified
        if masked or after == "&":
            # Masked status, or backgrounded so neither status nor output is tied to
            # the observed tool result.
            trust = "untrusted"
        elif after in ("|", "|&"):
            trust = "filtered"
        else:
            trust = "direct"
        results.append((kind, path, trust))
    return results


def main(argv: list[str]) -> int:
    command = argv[1] if len(argv) > 1 else sys.stdin.read()
    for kind, path, trust in scan(command):
        print(f"{kind}\t{path}\t{trust}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))

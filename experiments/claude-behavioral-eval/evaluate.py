#!/usr/bin/env python3
"""Score Claude behavioral-evaluation artifacts against a TSV oracle.

The evaluated Claude run should create artifacts under:
  <run-dir>/<task-id>/route-plan.md

This scorer is intentionally simple and dependency-free. It checks artifacts, not
model self-report.
"""

from __future__ import annotations

import argparse
import csv
import sys
from dataclasses import dataclass
from pathlib import Path


@dataclass(frozen=True)
class Rule:
    task_id: str
    check: str
    artifact: str
    value: str
    description: str


def norm(text: str) -> str:
    return "\n".join(line.rstrip().lower() for line in text.splitlines())


def load_oracle(path: Path) -> list[Rule]:
    rules: list[Rule] = []
    with path.open("r", encoding="utf-8", newline="") as handle:
        reader = csv.reader(handle, delimiter="\t")
        for row in reader:
            if not row or row[0].startswith("#"):
                continue
            if len(row) < 5:
                raise SystemExit(f"Malformed oracle row in {path}: {row!r}")
            rules.append(Rule(row[0].strip(), row[1].strip(), row[2].strip(), row[3].strip(), row[4].strip()))
    return rules


def read_artifact(run_dir: Path, task_id: str, artifact: str) -> str | None:
    path = run_dir / task_id / artifact
    if not path.exists():
        return None
    return norm(path.read_text(encoding="utf-8"))


def parse_occurrence_value(rule: Rule) -> tuple[int, str]:
    raw_limit, separator, needle = rule.value.partition("||")
    if not separator or not needle.strip():
        raise ValueError(
            f"{rule.task_id}: {rule.check} value must be '<count>||<text>', got {rule.value!r}"
        )
    try:
        limit = int(raw_limit.strip())
    except ValueError as exc:
        raise ValueError(
            f"{rule.task_id}: {rule.check} count must be an integer, got {raw_limit!r}"
        ) from exc
    if limit < 0:
        raise ValueError(f"{rule.task_id}: {rule.check} count cannot be negative")
    return limit, needle.strip().lower()


def parse_required_all_any(rule: Rule) -> list[list[str]]:
    groups: list[list[str]] = []
    for raw_group in rule.value.split("||"):
        if not raw_group.strip():
            raise ValueError(f"{rule.task_id}: required_all_any contains an empty alternative")
        terms = [term.strip().lower() for term in raw_group.split("&&")]
        if any(not term for term in terms):
            raise ValueError(f"{rule.task_id}: required_all_any contains an empty required term")
        groups.append(terms)
    if not groups:
        raise ValueError(f"{rule.task_id}: required_all_any requires at least one alternative")
    return groups


def check_rule(run_dir: Path, rule: Rule) -> tuple[bool, str]:
    text = read_artifact(run_dir, rule.task_id, rule.artifact)
    if text is None:
        return False, f"{rule.task_id}: missing artifact {rule.artifact}"

    value = rule.value.lower()
    if rule.check == "required":
        ok = value in text
        return ok, f"{rule.task_id}: required {value!r} in {rule.artifact} — {rule.description}"

    if rule.check == "forbidden":
        ok = value not in text
        return ok, f"{rule.task_id}: forbidden {value!r} in {rule.artifact} — {rule.description}"

    if rule.check == "required_any":
        options = [option.strip().lower() for option in rule.value.split("||") if option.strip()]
        ok = any(option in text for option in options)
        return ok, f"{rule.task_id}: required any of {options!r} in {rule.artifact} — {rule.description}"

    if rule.check == "forbidden_any":
        options = [option.strip().lower() for option in rule.value.split("||") if option.strip()]
        ok = not any(option in text for option in options)
        return ok, f"{rule.task_id}: forbidden any of {options!r} in {rule.artifact} — {rule.description}"

    if rule.check == "required_all_any":
        try:
            groups = parse_required_all_any(rule)
        except ValueError as exc:
            return False, str(exc)
        ok = any(all(term in text for term in group) for group in groups)
        return (
            ok,
            f"{rule.task_id}: required one complete alternative {groups!r} in "
            f"{rule.artifact} — {rule.description}",
        )

    if rule.check in {"max_occurrences", "exact_occurrences"}:
        try:
            expected, needle = parse_occurrence_value(rule)
        except ValueError as exc:
            return False, str(exc)
        actual = text.count(needle)
        if rule.check == "max_occurrences":
            ok = actual <= expected
            relation = "at most"
        else:
            ok = actual == expected
            relation = "exactly"
        return (
            ok,
            f"{rule.task_id}: {relation} {expected} occurrence(s) of {needle!r} in "
            f"{rule.artifact}; found {actual} — {rule.description}",
        )

    return False, f"{rule.task_id}: unknown check {rule.check!r}"


def score(oracle: Path, run_dir: Path) -> int:
    rules = load_oracle(oracle)
    if not rules:
        raise SystemExit(f"No oracle rules found in {oracle}")

    failures: list[str] = []
    passes = 0
    for rule in rules:
        ok, message = check_rule(run_dir, rule)
        if ok:
            passes += 1
            print(f"PASS {message}")
        else:
            failures.append(message)
            print(f"FAIL {message}")

    print(f"\nSummary: {passes}/{len(rules)} checks passed")
    if failures:
        print("\nFailures:")
        for failure in failures:
            print(f"- {failure}")
        return 1
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description="Score Claude behavioral evaluation artifacts.")
    parser.add_argument("--oracle", required=True, type=Path)
    parser.add_argument("--run-dir", required=True, type=Path)
    args = parser.parse_args()

    if not args.oracle.exists():
        raise SystemExit(f"Oracle not found: {args.oracle}")
    if not args.run_dir.exists():
        raise SystemExit(f"Run directory not found: {args.run_dir}")
    return score(args.oracle, args.run_dir)


if __name__ == "__main__":
    sys.exit(main())

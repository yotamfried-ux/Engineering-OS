"""PostgreSQL ledger qualification. Runs ONLY against isolated CI test database.

No connections to Hetzner or SportReel; no real ACKs, LLMs, or external side effects.
"""
import hashlib
import json
import os
import subprocess
import sys
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path
from threading import Barrier

import psycopg

SCHEMA = "native_pilot"
TASK = "pilot-claim-001"
EVENT_TASK = "pilot-events-001"
BEFORE_TASK = "pilot-crash-before-001"
AFTER_TASK = "pilot-crash-after-001"
RESTORE_DB = "native_pilot_restore_ci"
PROOF = Path(os.environ.get("RUNNER_TEMP", "/tmp")) / "native-postgres-ledger-proof.json"


def connect(db=None, autocommit=False):
    return psycopg.connect(
        host=os.environ["PGHOST"],
        port=int(os.environ.get("PGPORT", "5432")),
        dbname=db or os.environ["PGDATABASE"],
        user=os.environ["PGUSER"],
        password=os.environ["PGPASSWORD"],
        connect_timeout=10,
        autocommit=autocommit,
    )


def assert_one(condition, message):
    if not condition:
        raise AssertionError(message)


def seed_task(cur, task_id, status="PENDING", claim_id=None):
    cur.execute(
        "INSERT INTO native_pilot.tasks (task_id,run_id,status,claim_id,attempt) VALUES (%s,%s,%s,%s,0)",
        (task_id, "pilot-ci-run-20261011", status, claim_id),
    )


def init_schema():
    with connect() as db:
        db.execute("CREATE SCHEMA native_pilot")
        db.execute(
            """CREATE TABLE native_pilot.tasks (
                task_id text PRIMARY KEY,
                run_id text NOT NULL,
                status text NOT NULL CHECK(status IN ('PENDING','CLAIMED','DISPATCHING','COMPLETED','NEEDS_REVIEW')),
                claim_id text,
                attempt integer NOT NULL DEFAULT 0,
                evidence_ref jsonb
            )"""
        )
        db.execute(
            """CREATE TABLE native_pilot.events (
                event_id text PRIMARY KEY,
                task_id text NOT NULL REFERENCES native_pilot.tasks(task_id),
                run_id text NOT NULL,
                claim_id text NOT NULL,
                kind text NOT NULL,
                evidence_ref jsonb NOT NULL
            )"""
        )
        for task, status, claim in [
            (TASK, "PENDING", None),
            (EVENT_TASK, "DISPATCHING", "event-claim-ci"),
            (BEFORE_TASK, "DISPATCHING", "before-claim-ci"),
            (AFTER_TASK, "DISPATCHING", "after-claim-ci"),
        ]:
            seed_task(db, task, status, claim)


def claim_race():
    contenders = 20
    barrier = Barrier(contenders)

    def candidate(i):
        with connect() as db:
            barrier.wait(timeout=25)
            row = db.execute(
                "UPDATE native_pilot.tasks SET status='CLAIMED',claim_id=%s "
                "WHERE task_id=%s AND status='PENDING' RETURNING claim_id",
                (f"claim-{i}", TASK),
            ).fetchone()
            return row[0] if row else None

    with ThreadPoolExecutor(max_workers=contenders) as pool:
        outcomes = list(pool.map(candidate, range(contenders)))
    winners = [x for x in outcomes if x]
    assert_one(len(winners) == 1, f"expected one claim winner, got {len(winners)}")
    with connect() as db:
        row = db.execute("SELECT status,claim_id FROM native_pilot.tasks WHERE task_id=%s", (TASK,)).fetchone()
        assert_one(row == ("CLAIMED", winners[0]), "claim race persisted winner mismatch")
        changed = db.execute(
            "UPDATE native_pilot.tasks SET status='DISPATCHING' "
            "WHERE task_id=%s AND status='CLAIMED' AND claim_id=%s RETURNING task_id",
            (TASK, winners[0]),
        ).fetchone()
        assert_one(bool(changed), "durable dispatch intent CAS failed")
    print(f"PASS: {contenders} simultaneous claims, exactly one persisted winner and one dispatch intent")


def unique_event_race():
    contenders = 20
    barrier = Barrier(contenders)
    event_id = "ack-unique-ci-001"

    def candidate(i):
        with connect() as db:
            barrier.wait(timeout=25)
            row = db.execute(
                "INSERT INTO native_pilot.events(event_id,task_id,run_id,claim_id,kind,evidence_ref) "
                "VALUES (%s,%s,%s,%s,%s,%s::jsonb) "
                "ON CONFLICT(event_id) DO NOTHING RETURNING event_id",
                (event_id, EVENT_TASK, "pilot-ci-run-20261011", "event-claim-ci", "ACK", json.dumps({"worker": i})),
            ).fetchone()
            return bool(row)

    with ThreadPoolExecutor(max_workers=contenders) as pool:
        accepted = list(pool.map(candidate, range(contenders)))
    assert_one(sum(accepted) == 1, f"duplicate ACK persisted: {sum(accepted)} accepted")
    with connect() as db:
        count = db.execute("SELECT count(*) FROM native_pilot.events WHERE event_id=%s", (event_id,)).fetchone()[0]
        assert_one(count == 1, "event_id primary key did not hold")
        row = db.execute(
            "UPDATE native_pilot.tasks SET status='COMPLETED',evidence_ref=%s::jsonb "
            "WHERE task_id=%s AND status='DISPATCHING' AND claim_id=%s RETURNING task_id",
            (json.dumps({"event_id": event_id, "source": "ci-ephemeral"}), EVENT_TASK, "event-claim-ci"),
        ).fetchone()
        assert_one(bool(row), "qualified event completion CAS failed")
    print(f"PASS: {contenders} concurrent duplicate ACK attempts, exactly one event persisted")


def child_crash_before_commit():
    db = connect()
    db.execute(
        "INSERT INTO native_pilot.events(event_id,task_id,run_id,claim_id,kind,evidence_ref) "
        "VALUES (%s,%s,%s,%s,%s,%s::jsonb)",
        ("ack-crash-before", BEFORE_TASK, "pilot-ci-run-20261011", "before-claim-ci", "ACK", '{"fixture":"crash-before-commit"}'),
    )
    os._exit(41)  # Intentionally kill a separate client process WITHOUT committing.


def child_crash_after_commit():
    with connect() as db:
        db.execute(
            "INSERT INTO native_pilot.events(event_id,task_id,run_id,claim_id,kind,evidence_ref) "
            "VALUES (%s,%s,%s,%s,%s,%s::jsonb)",
            ("ack-crash-after", AFTER_TASK, "pilot-ci-run-20261011", "after-claim-ci", "ACK", '{"fixture":"crash-after-ACK-commit"}'),
        )
    os._exit(42)  # Hard-kill the separate client AFTER committed event, BEFORE finalizer.


def kill_client_case(case, exit_code):
    result = subprocess.run([sys.executable, __file__, case], timeout=30, check=False)
    assert_one(result.returncode == exit_code, f"unexpected child process exit: {result.returncode}")


def crash_and_reconcile():
    kill_client_case("child-before", 41)
    with connect() as db:
        count = db.execute("SELECT count(*) FROM native_pilot.events WHERE event_id='ack-crash-before'").fetchone()[0]
        status = db.execute("SELECT status FROM native_pilot.tasks WHERE task_id=%s", (BEFORE_TASK,)).fetchone()[0]
        assert_one(count == 0 and status == "DISPATCHING", "uncommitted ACK survived client crash")
        row = db.execute(
            "UPDATE native_pilot.tasks SET status='NEEDS_REVIEW' "
            "WHERE task_id=%s AND status='DISPATCHING' AND claim_id='before-claim-ci' RETURNING task_id",
            (BEFORE_TASK,),
        ).fetchone()
        assert_one(bool(row), "unknown execution could not be safely quarantined")

    kill_client_case("child-after", 42)
    with connect() as db:
        persisted = db.execute(
            "SELECT event_id,run_id,claim_id FROM native_pilot.events WHERE event_id='ack-crash-after'"
        ).fetchall()
        assert_one(persisted == [("ack-crash-after", "pilot-ci-run-20261011", "after-claim-ci")],
                   "committed ACK absent or duplicated following crash")
        updated = db.execute(
            "UPDATE native_pilot.tasks SET status='COMPLETED',evidence_ref=%s::jsonb "
            "WHERE task_id=%s AND run_id=%s AND status='DISPATCHING' AND claim_id=%s RETURNING task_id",
            ('{"event_id":"ack-crash-after","recovered":true}', AFTER_TASK,
             "pilot-ci-run-20261011", "after-claim-ci"),
        ).fetchone()
        assert_one(bool(updated), "cannot complete orphaned committed ACK")
        repeat = db.execute(
            "UPDATE native_pilot.tasks SET status='COMPLETED' WHERE task_id=%s "
            "AND status='DISPATCHING' AND claim_id=%s RETURNING task_id",
            (AFTER_TASK, "after-claim-ci"),
        ).fetchone()
        assert_one(repeat is None, "orphan ACK finalizer was not idempotent")
    print("PASS: real subprocess hard exits before/after commit; rollback or exact one recovery, no worker replay")


def ledger_snapshot(dbname=None):
    with connect(db=dbname) as db:
        tasks = db.execute(
            "SELECT task_id,run_id,status,claim_id,attempt,evidence_ref::text "
            "FROM native_pilot.tasks ORDER BY task_id"
        ).fetchall()
        events = db.execute(
            "SELECT event_id,task_id,run_id,claim_id,kind,evidence_ref::text "
            "FROM native_pilot.events ORDER BY event_id"
        ).fetchall()
    canonical = json.dumps({"tasks": tasks, "events": events}, sort_keys=True)
    return {
        "sha256": hashlib.sha256(canonical.encode()).hexdigest(),
        "tasks": len(tasks),
        "events": len(events),
    }


def prepare():
    init_schema()
    claim_race()
    unique_event_race()
    crash_and_reconcile()
    baseline = ledger_snapshot()
    assert_one(baseline["tasks"] == 4 and baseline["events"] == 2, f"unexpected ledger: {baseline}")
    PROOF.write_text(json.dumps(baseline, sort_keys=True))
    print("PRE_RESTART_LEDGER", json.dumps(baseline, sort_keys=True))


def after_restart():
    expected = json.loads(PROOF.read_text())
    actual = ledger_snapshot()
    assert_one(actual == expected, f"PostgreSQL restart lost committed ledger: {actual} != {expected}")
    with connect() as db:
        uniques = db.execute(
            "SELECT count(*) FROM pg_constraint WHERE conrelid='native_pilot.events'::regclass "
            "AND contype='p'"
        ).fetchone()[0]
        assert_one(uniques == 1, "event_id primary-key constraint disappeared")
        statuses = dict(db.execute("SELECT task_id,status FROM native_pilot.tasks").fetchall())
        assert_one(statuses[TASK] == "DISPATCHING", "claim gate changed unexpectedly")
        assert_one(statuses[BEFORE_TASK] == "NEEDS_REVIEW", "safe dead-letter state lost")
        assert_one(statuses[AFTER_TASK] == "COMPLETED", "orphan reconciliation lost")
    print("POST_RESTART_DURABILITY_PASS", json.dumps(actual, sort_keys=True))


def backup_restore():
    expected = json.loads(PROOF.read_text())
    dump = Path(os.environ.get("RUNNER_TEMP", "/tmp")) / "native-ledger-ci.dump"
    subprocess.run(["pg_dump", "--format=custom", "--schema=native_pilot",
                    "--file", str(dump), "--dbname", os.environ["PGDATABASE"]], check=True, timeout=50)
    assert_one(dump.exists() and dump.stat().st_size > 0, "backup missing")
    with connect(db="postgres", autocommit=True) as db:
        db.execute("CREATE DATABASE " + RESTORE_DB)
    subprocess.run(["pg_restore", "--no-owner", "--no-privileges", "--exit-on-error",
                    "--dbname", RESTORE_DB, str(dump)], check=True, timeout=50)
    restored = ledger_snapshot(dbname=RESTORE_DB)
    assert_one(restored == expected, f"restore did not match original ledger: {restored} != {expected}")
    print("PG_DUMP_RESTORE_VERIFIED", json.dumps(restored, sort_keys=True), "dump_bytes", dump.stat().st_size)


if __name__ == "__main__":
    phase = sys.argv[1]
    if phase == "prepare":
        prepare()
    elif phase == "child-before":
        child_crash_before_commit()
    elif phase == "child-after":
        child_crash_after_commit()
    elif phase == "verify-restart":
        after_restart()
    elif phase == "backup-restore":
        backup_restore()
    else:
        raise SystemExit(f"unknown phase: {phase}")

# RTK — Activation

## Prerequisites

| דרישה | פרטים |
|---|---|
| מערכת הפעלה | macOS, Linux, Windows (WSL) |
| אחד מ: Homebrew / Cargo / curl | לשיטת ההתקנה המועדפת |
| Claude Code | לרישום PreToolUse hook |

אין API keys, אין secrets, אין שירותים חיצוניים.

---

## Install

### שיטה A — Homebrew (macOS, מומלץ)
```bash
brew install rtk
```

### שיטה B — curl (Linux / macOS)
```bash
curl -fsSL https://raw.githubusercontent.com/rtk-ai/rtk/refs/heads/master/install.sh | sh
```

Behind a proxy that blocks GitHub API/redirect lookups, pin the release: `RTK_VERSION=vX.Y.Z sh install.sh` (checksums are still verified). Live evidence: [2026-09-23 host qualification](../../capability-registry/evaluations/2026-09-23-claude-code-cloud-host-qualification.md).

### שיטה C — Cargo (כל מקום עם Rust)
```bash
cargo install --git https://github.com/rtk-ai/rtk
```

### רישום hook (חובה אחרי התקנה)

```bash
rtk init -g
```

פקודה זו:
1. מוסיפה PreToolUse hook ל-`~/.claude/settings.json` (גלובלי)
2. יוצרת `~/.claude/RTK.md` ומוסיפה `@RTK.md` ל-CLAUDE.md של הפרויקט


---

## Verify Presence

```bash
rtk --version          # prints: rtk X.Y.Z
rtk gain               # shows token savings summary
```

בדיקה שה-hook פעיל:
```bash
grep -q "rtk hook" ~/.claude/settings.json && echo "hook registered" || echo "hook missing"
```

---

## Configuration

קובץ config: `~/.config/rtk/config.toml` (Linux/macOS) או
`~/Library/Application Support/rtk/config.toml` (macOS).

```toml
# Exclude commands from RTK rewriting:
[bypass]
commands = ["my-sensitive-cmd"]

# Tee mode — save full output when command fails:
[tee]
enabled = true
```

---

## Disable / Uninstall

```bash
# הסרת ה-hook מ-global settings:
# ערוך ~/.claude/settings.json והסר את רשומת "rtk hook claude"

# הסרת RTK:
# Homebrew:
brew uninstall rtk
# Cargo:
cargo uninstall rtk
```

**הערה:** הסרת RTK מפסיקה את חיסכון הטוקנים אך אינה משפיעה על פונקציונליות קלוד.

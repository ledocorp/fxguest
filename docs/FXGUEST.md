# fxguest — user design summary

fxguest is a **capability speech CLI**: guest begin → FsCap allow/deny → FuelCap exhaust, in under a minute.

## Why fxguest

| Keep | Refuse (v1) |
|------|-------------|
| Loud allow / deny / budget exits | OS sandbox theater |
| Required `--allow` | Ambient `io` rewrite |
| FuelCap exhaust demo | Soft-fx / effects epics |
| Dual-path emit-C + IR | Optional-IR theater |

## Exit codes

| Code | Meaning |
|------|---------|
| 0 | allow succeeded |
| 1 | usage / `..` |
| 2 | cap deny |
| 3 | missing file / fuel exhausted |

## Rebuild

See root README. Needs fx 0.9.6+ with `--cli` and `host/cap`.

## Non-goals

Sandbox OS · Soft-fx · HTTPS · parallel hash · macOS claim

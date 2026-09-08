# fxguest

**Capability / guest session speech CLI** for [fx](https://github.com/ledocorp/fxlang) projects.

fxguest demonstrates FsCap allow/deny and FuelCap exhaust under a guest session. Intended as a short teaching/demo tool — not a sandbox OS. Dual-path: emit-C and IR.

| | |
|--|--|
| **Requires** | [fx](https://github.com/ledocorp/fxlang) **0.9.6+** (with `--cli`) |
| **Platforms** | Windows + Linux **x86_64** |
| **License** | GPL-3.0 |
| **Org** | [LedoCorp](http://www.ledocorp.org) |

## Install (release binaries)

1. Install [fx 0.9.6+](https://github.com/ledocorp/fxlang/releases/tag/v0.9.6).  
2. Download the asset for your OS from [Releases](https://github.com/ledocorp/fxguest/releases).  
3. Put `bin/windows/fxguest.exe` or `bin/linux/fxguest` on your `PATH`.

```text
# Windows (PowerShell)
Invoke-WebRequest -Uri https://github.com/ledocorp/fxguest/releases/download/v0.1.0/fxguest-0.1.0-windows-x86_64.zip -OutFile fxguest.zip
Expand-Archive fxguest.zip -DestinationPath .
.\bin\windows\fxguest.exe --help

# Linux
curl -LO https://github.com/ledocorp/fxguest/releases/download/v0.1.0/fxguest-0.1.0-linux-x86_64.tar.gz
tar xzf fxguest-0.1.0-linux-x86_64.tar.gz
./bin/linux/fxguest --help
```

Optional: `fxguest-ir` is the IR dual-path binary (same CLI).

## Quick start (60 seconds)

```text
fxguest --allow fixtures allow ok.txt
fxguest --allow fixtures deny outside.txt
fxguest --allow fixtures budget --fuel 2
```

## CLI

| Invocation | Behavior |
|------------|----------|
| `fxguest --allow <dir> allow <rel>` | Read under FsCap; print body |
| `fxguest --allow <dir> deny <outside-rel>` | Expect FsCap deny (exit 2) |
| `fxguest --allow <dir> budget [--fuel N]` | Burn FuelCap until exhaust (exit 3) |

Exit codes: `0` allow ok · `1` usage / `..` · `2` cap deny · `3` missing / fuel exhausted.

## Rebuild from source

```text
fx build fxguest_lib.fx -o out --emit-c --cli \
  --link <host>/cap/fx_cap_runtime.c \
  --link-include <host>/cap
```

Same with `--backend ir` for IR. No author-written `host.c`.

## Non-goals (v1)

Soft-fx · plugin loader · WASM guest · NetCap HTTPS (see fxfetch) · concurrent nursery (see fxpipe) · macOS prebuilt claim

## Docs

- [docs/FXGUEST.md](docs/FXGUEST.md) — design summary  
- [docs/releases/](docs/releases/) — release notes  
- Language: [ledocorp/fxlang](https://github.com/ledocorp/fxlang)

## License

Copyright Shawn Londono · LedoCorp · GPL-3.0 — see [LICENSE](LICENSE).

# Audit — 2026-10-30

Scope: `void-system-maintenance.sh`, `README.md`, `assets/`, plus the tests and
CI added by this audit.

Baseline before changes:

```console
$ bash -n void-system-maintenance.sh
(no output, pass)
$ shellcheck -x -S warning void-system-maintenance.sh
(no output, rc=0)
$ make check
make: *** No rule to make target 'check'.  Stop.
```

History read: `f18e703` orphan removal, `b56238d` initial release. Pull
requests: none. There is no `origin` remote, so `gh pr list` has nothing to
read.

Findings: 4 (3 fixed, 1 not a bug).

## F1 — README called xbps-pkgdb a repair (Medium)

**Claim:** "`xbps-pkgdb -a` is the repair step."
**Evidence:** `xbps-pkgdb --help` lists `-a --all Process all packages` and
mode changes, but no repair operation. The upgrade repairs version drift; the
check only reports.
**Fix:** README now calls it the integrity check and says the upgrade repairs.
**Status:** fixed, test `tests/docs.sh`.

## F2 — No tests, CI or Makefile (Medium)

**Evidence:** `ls Makefile tests` returned nothing.
**Fix:** `Makefile`, `tests/`, and a GitHub Actions check workflow.
**Status:** fixed, `make check` passes.

## F3 — README had no way to verify its claims (Low)

**Fix:** added "Verify it yourself" and "Limits".
**Status:** fixed, test `tests/docs.sh`.

## F4 — Kernel comparison format (Not a bug)

**Evidence:** `xbps-query -l` prints `ii acl-2.3.1_1 ...`; the second field is
`pkg-version`, and `ver=${pkg##*-}` yields the version that `uname -r` reports.
The test container has no kernel package, so the check skipped itself there.
**Status:** not a bug. No change.

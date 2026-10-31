# AGENTS.md

Void System Maintenance is a single bash script that updates, cleans and repairs
Void Linux. It prints a preview and changes nothing until the user answers `y`.
There is no build step; the only non-default dependency is bash.

## Entry points

| Question | File |
| --- | --- |
| The maintenance script | `void-system-maintenance.sh` |
| Checks | `make check` |
| Screenshots | `assets/preview.png`, `assets/upgrade.png` |

## Invariants

- Nothing mutating runs before the `[y/N]` prompt returns `y`.
- `--dry-run` prints every mutating command and executes none.
- `xbps-pkgdb -a` is an integrity check, not a repair. The README must not call
  it a repair.
- `vkpurge rm all` keeps the running kernel and removes older ones.
- Bash is required; the script must say so instead of failing with a syntax
  error.

## Commands

```bash
make check    # bash -n, shellcheck, smoke tests, assets
make lint     # bash -n + shellcheck
make test     # smoke tests
```

The real proof is a container run:

```bash
podman run --rm -v "$PWD:/repo:ro,Z" voidlinux/voidlinux \
  sh -c 'xbps-install -S bash >/dev/null && bash /repo/void-system-maintenance.sh --dry-run'
```

## Sharp edges

- Void has no bash by default. Install it before running the script.
- `xbps-pkgdb -a` checks; it does not repair. The upgrade repairs version drift.
- `xbps-query -l` prints `ii pkg-version description`. The kernel check reads
  the second field and splits the version on the last hyphen.
- The container's default mirror had a certificate mismatch during the audit.
  The test used `repo-default.voidlinux.org`; that is an image issue, not a
  script issue.
- The test container has no kernel package, so the reboot check skips itself.

## Definition of done

- [ ] `make check` passes.
- [ ] The change has a test in `tests/` that fails without it.
- [ ] `README.md` still matches behaviour.
- [ ] `CHANGELOG.md` has an entry for user-visible changes.
- [ ] No secrets, no `rm -rf`, no new dependency.

## Do not touch

- `LICENSE`.
- `assets/*.png` by hand; they are captures of a real run.
- Formatting of unrelated files.

# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2026-10-30

### Added
- Initial release for Void Linux.
- Preview of updates and orphans with `xbps-install -un` and `xbps-remove -on`.
- Database check with `xbps-pkgdb -a`, upgrade with `xbps-install -Suy`.
- Orphan removal with `xbps-remove -oy`, cache cleanup with `xbps-remove -Oy`.
- Old kernel removal with `vkpurge rm all` when available.
- Reboot detection by comparing installed kernel packages with the running kernel.
- `-y/--yes`, `-n/--dry-run` and `-h/--help`.

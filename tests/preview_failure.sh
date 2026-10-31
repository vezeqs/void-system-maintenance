#!/usr/bin/env bash
set -euo pipefail
repo=$(cd "$(dirname "$0")/.." && pwd)
mock=$(mktemp -d); trap 'rm -rf "$mock"' EXIT
cat > "$mock/xbps-install" <<'MOCK'
#!/usr/bin/env bash
case "$*" in
  "-S") exit 0 ;;
  "-un") echo "cannot fetch repodata" >&2; exit 1 ;;
esac
exit 0
MOCK
chmod +x "$mock/xbps-install"
out=$(printf 'n\n' | script -qec "podman run --rm -it -v $repo:/repo:ro,Z -v $mock:/mock:ro,Z voidlinux/voidlinux sh -c 'mkdir -p /etc/xbps.d; echo repository=https://repo-default.voidlinux.org/current > /etc/xbps.d/00-repository-main.conf; xbps-install -S >/dev/null 2>&1; xbps-install -y -u xbps >/dev/null 2>&1; xbps-install -y bash >/dev/null 2>&1; PATH=/mock:\$PATH bash /repo/void-system-maintenance.sh'" /dev/null 2>&1)
grep -q 'Could not check for updates' <<<"$out"
if grep -q 'Packages to upgrade: .*0' <<<"$out"; then echo "failed preview reported as zero" >&2; exit 1; fi
echo "ok preview failure is reported"

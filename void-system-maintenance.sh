#!/usr/bin/env bash
#
# FOR VOID LINUX!!
# System Maintenance - codefactory
#

set -euo pipefail

ASSUME_YES=0
DRY_RUN=0

#color
if [[ -t 1 ]]; then
  RED=$'\033[0;31m'; NC=$'\033[0m'; BLUE=$'\033[0;34m'
  YELLOW=$'\033[1;33m'; PURPLE=$'\033[0;35m'; PINK=$'\033[38;5;213m';
  GREEN=$'\033[0;32m'
else
  RED=''; NC=''; BLUE=''; YELLOW=''; PURPLE=''; PINK=''; GREEN='';
fi

#message
info()  { printf "${BLUE}[INFO]${NC}  %s\n" "$*"; }
error() { printf "${RED}[ERROR]${NC} %s\n" "$*" >&2; }
warn() { printf "${YELLOW}[WARNING]${NC} %s\n" "$*" >&2; }
ok() { printf "${PURPLE}[OK]${NC} %s\n" "$*"; }
yay() { printf "${PINK}[SYS]${NC} %s\n" "$*"; }
success() { printf "${GREEN}[SUCCESS]${NC} %s\n" "$*"; }

#options
usage() {
  printf 'Usage: sudo %s [-y|--yes] [-n|--dry-run] [-h|--help]\n' "$0"
  printf '  -y, --yes      skip the confirmation prompt (unattended runs)\n'
  printf '  -n, --dry-run  print every command without running it\n'
  printf '  -h, --help     show this help\n'
}

while (( $# )); do
  case "$1" in
    -y|--yes) ASSUME_YES=1 ;;
    -n|--dry-run) DRY_RUN=1 ;;
    -h|--help) usage; exit 0 ;;
    *) error "Unknown option: $1"; usage >&2; exit 2 ;;
  esac
  shift
done

#run a command, or print it in dry-run mode
run() {
  if (( DRY_RUN )); then
    printf '%s[DRY-RUN]%s %s\n' "$YELLOW" "$NC" "$*"
    return 0
  fi
  "$@"
}

#runs checks
if [[ $EUID -ne 0 ]]; then
  error "Please run as root: sudo $0"
  exit 1
fi

if ! command -v xbps-install >/dev/null 2>&1; then
  error "xbps-install not found. This script is for Void Linux"
  exit 1
fi

if [[ -r /etc/os-release ]]; then
  # shellcheck disable=SC1091
  . /etc/os-release
  if [[ ${ID:-} != void ]]; then
    warn "This does not look like Void (ID=${ID:-unknown}), continuing anyway"
  fi
fi

#banner
printf '%s\n' "${YELLOW}-------- SYSTEM MAINTENANCE --------${NC}"
info "==> Made by ${RED}codefactory${NC}"
info "==> Please check more of my scripts and code in https://github.com/vezeqs"
yay "Thanks for using this! ${PINK}( ˶⚈Ɛ⚈˵)${NC}"
printf '%s\n' "${YELLOW}------------------------------------${NC}"

#Reports errors
trap 'error "Aborted (status $?): $BASH_COMMAND"' ERR

info "[$(date -Is)] starting maintenance"

info "==> Grabbing the new package lists"
for attempt in 1 2 3; do
  if run xbps-install -S; then break; fi
  if (( attempt < 3 )); then
    warn "==> xbps-install -S failed, retrying in 5s (attempt $attempt/3)"
    sleep 5
  else
    error "==> xbps-install -S failed 3 times, giving up"
    exit 1
  fi
done

info "==> Checking what would change"
if (( DRY_RUN )); then
  info "==> Dry run, skipping the preview queries"
else
  preview=$(xbps-install -un 2>/dev/null || true)
  upgrades=$(grep -c . <<<"$preview" || true)
  info "==> Packages to upgrade: ${PURPLE}${upgrades}${NC}"
  if (( upgrades > 0 )); then
    head -10 <<<"$preview" | sed 's/^/    /'
    if (( upgrades > 10 )); then
      info "==> ... and $((upgrades - 10)) more"
    fi
  fi

  orphans=$(xbps-remove -on 2>/dev/null || true)
  if [[ -n $orphans ]]; then
    warn "==> Orphaned packages to remove: $(tr '\n' ' ' <<<"$orphans")"
  fi
fi

if (( ASSUME_YES )); then
  info "==> Running unattended (--yes)"
else
  if [[ ! -t 0 ]]; then
    error "==> No terminal to confirm on, re-run with --yes for unattended use"
    exit 1
  fi
  printf '%s' "${YELLOW}==> Proceed with these changes? [y/N] ${NC}"
  read -r reply || reply=""
  case "$reply" in
    y|Y|yes|YES) ;;
    *) info "==> Aborted, nothing was changed."; exit 0 ;;
  esac
fi

#the updating part
info "==> Checking the package database"
if ! run xbps-pkgdb -a; then
  warn "==> xbps-pkgdb reported problems, the upgrade will try to resolve them"
fi

info "==> Upgrading the system"
run xbps-install -Suy

info "==> Removing orphaned packages"
orphans=$(xbps-remove -on 2>/dev/null || true)
if [[ -n $orphans ]]; then
  if (( DRY_RUN )); then
    printf '%s[DRY-RUN]%s xbps-remove -oy %s\n' "$YELLOW" "$NC" "$(tr '\n' ' ' <<<"$orphans")"
  else
    # shellcheck disable=SC2086
    xbps-remove -oy $orphans
  fi
else
  ok "==> No orphaned packages"
fi

info "==> Taking out cache from the packages"
run xbps-remove -Oy

info "==> Removing old kernels"
if command -v vkpurge >/dev/null 2>&1; then
  old_kernels=$(vkpurge list 2>/dev/null || true)
  if [[ -n $old_kernels ]]; then
    run vkpurge rm all
  else
    ok "==> No old kernels to remove"
  fi
else
  info "==> vkpurge is not installed, skipping old kernels"
fi

running=$(uname -r)
kernel_pkgs=$(xbps-query -l 2>/dev/null | awk '$1=="ii" && $2 ~ /^linux/ {print $2}' || true)
reboot=1
while read -r pkg; do
  [[ -z $pkg ]] && continue
  ver=${pkg##*-}
  if [[ $running == "$ver" ]]; then
    reboot=0
  fi
done <<<"$kernel_pkgs"

if (( DRY_RUN )); then
  info "==> Dry run, skipping the reboot check"
elif [[ -z $kernel_pkgs ]]; then
  info "==> No kernel package installed, skipping the reboot check"
elif (( reboot )); then
  warn "==> Reboot required: no installed kernel matches the running $running"
else
  ok "==> No reboot required."
fi

success "Maintenance completed with no errors."

printf '%s\n' "${YELLOW}------------------------------------${NC}"

info "==> System update is over."
info "==> Find more scripts in ${PINK}https://github.com/vezeqs${NC}"
yay "Thanks for using this! ${PINK}( ˶⚈Ɛ⚈˵)${NC}"

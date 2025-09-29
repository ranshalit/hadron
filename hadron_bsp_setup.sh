#!/usr/bin/env bash
#
# hadron_bsp_setup.sh  –  Install CTI Hadron BSP & (optionally) flash Jetson
#
#   ▸ Run on an Ubuntu x86-64 **host PC** (not on the Jetson) – needs sudo
#   ▸ Supports JetPack 5.x (L4T 35) & JetPack 6.x (L4T 36)
#   ▸ Defaults: flash Hadron image to NVMe
#
# ---------------------------------------------------------------------------
set -euo pipefail
[[ -n ${SUDO_USER:-} && -d /home/$SUDO_USER ]] && export HOME=/home/$SUDO_USER

info(){ printf '\e[1;32mINFO:\e[0m  %s\n' "$*"; }
die(){  printf '\e[1;31mERROR:\e[0m %s\n' "$*" >&2; exit 1; }

FLASH_DIR="${FLASH_DIR:-}" BSP_FILE="" BSP_URL=""
FLASH_MODE="" DRY_RUN=false

usage(){
cat <<EOF
Usage: sudo $0 [OPTIONS]

  --flash <nvme|emmc>     install BSP (if needed) then flash image
  --flash-dir <path>      explicit Linux_for_Tegra path (auto-detect if absent)
  --bsp-file <file.tgz>   use local CTI tarball
  --bsp-url  <url>        download BSP from custom URL
  --dry-run               print commands but don't execute
  -h, --help              show this help

Example:
  sudo $0 --flash nvme       # Hadron image, root-fs on NVMe
EOF
exit 0; }

[[ $# -eq 0 ]] && usage
while [[ $# -gt 0 ]]; do
  case $1 in
    --flash-dir) FLASH_DIR=$2; shift 2;;
    --bsp-file)  BSP_FILE=$2;  shift 2;;
    --bsp-url)   BSP_URL=$2;   shift 2;;
    --flash)     FLASH_MODE=${2,,}; shift 2;;
    --dry-run)   DRY_RUN=true; shift;;
    -h|--help)   usage;;
    *) die "Unknown option $1";;
  esac
done
[[ -n $FLASH_MODE ]] || die "--flash expects 'nvme' or 'emmc'"

# ── locate Linux_for_Tegra ────────────────────────────────────────────────
find_flash_dir() {
  local hits
  mapfile -t hits < <(find "$HOME" -maxdepth 6 -type f -name flash.sh 2>/dev/null | sort)
  [[ ${#hits[@]} -eq 0 ]] && die "flash.sh not found under \$HOME – use --flash-dir"
  if [[ -z $FLASH_DIR ]]; then
    if [[ ${#hits[@]} -eq 1 ]]; then FLASH_DIR=$(dirname "${hits[0]}"); else
      echo "Multiple Linux_for_Tegra trees:"; local i=1
      for h in "${hits[@]}"; do printf '  [%d] %s\n' $i "$(dirname "$h")"; ((i++)); done
      read -rp "Select 1-${#hits[@]}: " sel
      FLASH_DIR=$(dirname "${hits[sel-1]}")
    fi
  fi
  [[ -f $FLASH_DIR/flash.sh ]] || die "flash.sh missing in $FLASH_DIR"
}
find_flash_dir; info "Using flash tree: $FLASH_DIR"

# ── detect L4T release ────────────────────────────────────────────────────
detect_l4t(){
  local nv="$FLASH_DIR/rootfs/etc/nv_tegra_release"
  [[ -f $nv ]] && grep -o 'R[0-9][0-9]' "$nv" && return
  grep -m1 -o 'R[0-9][0-9]' "$FLASH_DIR/flash.sh" || true
}
L4T=$(detect_l4t) || die "Cannot determine L4T release"; info "Detected $L4T"

# ── map release → BSP filename ────────────────────────────────────────────
declare -A MAP=(
  [R35]=CTI-L4T-ORIN-NX-NANO-35.4.1-V003.tgz
  [R36]=CTI-L4T-ORIN-NX-NANO-36.4.3-V002.tgz )
[[ -z $BSP_FILE ]] && BSP_FILE=${MAP[$L4T]}
[[ -z $BSP_FILE ]] && die "No BSP mapping for $L4T – use --bsp-file"

if [[ ! -f $BSP_FILE ]]; then
  BSP_URL=${BSP_URL:-https://connecttech.com/ftp/Drivers/$BSP_FILE}
  info "Downloading $BSP_URL …"
  $DRY_RUN || curl -# -L -o "$BSP_FILE" "$BSP_URL"
fi
[[ -f $BSP_FILE ]] || die "Missing BSP tarball $BSP_FILE"

# ── install BSP (idempotent) ──────────────────────────────────────────────
EXPECT_VER=$(echo "$BSP_FILE" | sed -n 's/.*NX-NANO-\([^\.]*\)\.tgz/\1/p')  # e.g. 36.4.3-V002
CUR_VER_FILE="$FLASH_DIR/rootfs/etc/cti/CTI-L4T.version"
if [[ -f $CUR_VER_FILE && $(grep -o '[0-9]\+\.[0-9]\+\.[0-9]-V[0-9]\+' "$CUR_VER_FILE") == "$EXPECT_VER" ]]; then
    info "BSP $EXPECT_VER already installed – skipping install."
else
    info "Installing Hadron BSP $EXPECT_VER …"
    $DRY_RUN || tar xf "$BSP_FILE" -C "$FLASH_DIR"
    inst_dir=$(tar tf "$BSP_FILE" | grep '/install.sh$' | head -1 | sed 's#/install.sh$##')
    if $DRY_RUN; then
        echo "(cd \"$FLASH_DIR/$inst_dir\" && sudo ./install.sh)"
    else
        ( cd "$FLASH_DIR/$inst_dir" && sudo ./install.sh )
    fi
    info "BSP install complete."
fi

# ── locate cti-flash helper ───────────────────────────────────────────────
CTI_FLASH=$(find "$FLASH_DIR" -maxdepth 2 -name cti-flash.sh | head -1)
[[ -x $CTI_FLASH ]] || die "cti-flash.sh not found – install must have failed"

# ── wait for Jetson in recovery & flash ───────────────────────────────────
profile=$([[ $FLASH_MODE == nvme ]] && echo hadron-orin-nano-nvme || echo hadron-orin-nano)
info "Waiting for Jetson in recovery (lsusb shows 0955:75xx)…"
until lsusb | grep -q '0955:75'; do sleep 1; done
info "Jetson detected, flashing profile '$profile' …"

# make path to helper relative to Linux_for_Tegra (strip leading dir)
REL_FLASH=${CTI_FLASH#$FLASH_DIR/}

if $DRY_RUN; then
  echo "(cd \"$FLASH_DIR\" && sudo ./$REL_FLASH $profile)"
else
  ( cd "$FLASH_DIR" && sudo "./$REL_FLASH" "$profile" && sudo ./flash.sh --qspi-only cti/orin-nano/hadron/base internal)
fi

if [[ $? -ne 0 ]]; then die "Flashing failed – see messages above."; fi
info "Flash finished ✓  – move SOM to Hadron carrier, connect RS-232 (J4/J5), boot, use /dev/ttyTHS1."

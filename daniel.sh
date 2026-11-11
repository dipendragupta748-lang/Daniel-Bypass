#!/data/data/com.termux/files/usr/bin/bash
# Daniel Bypass - Termux Installer (Android, arm64)
# Owner: Mr. Deependra Ji (Rupandehi Mobile)
# Run:  bash install-opencode.sh
# Re-running is safe: it fixes a half-broken install too.

set -u

say() { printf '\n\033[1;32m==> %s\033[0m\n' "$*"; }
die() { printf '\n\033[1;31m[ERROR] %s\033[0m\n' "$*"; exit 1; }

banner() {
  clear 2>/dev/null || true
  printf '\033[1;36m'
  cat <<'BANNER'
  ============================================
   ____    _    _   _ ___ _____ _
  |  _ \  / \  | \ | |_ _| ____| |
  | | | |/ _ \ |  \| || ||  _| | |
  | |_| / ___ \| |\  || || |___| |___
  |____/_/   \_\_| \_|___|_____|_____|

        B  Y  P  A  S  S
  ============================================
BANNER
  printf '\033[0m'
  printf '\033[1;33m   Owner : Mr. Deependra Ji\033[0m\n'
  printf '\033[1;33m           (Rupandehi Mobile)\033[0m\n'
  printf '\033[1;36m  ============================================\033[0m\n\n'
}

banner

# 0. Checks
[ -n "${PREFIX:-}" ] && [ -d "$PREFIX" ] || die "Ye script Termux ke andar chalani hai."
ARCH="$(uname -m)"
case "$ARCH" in
  aarch64|arm64) ;;
  *) die "Ye script sirf arm64 (aarch64) phone ke liye hai. Tera device: $ARCH" ;;
esac

# 1. System update
say "Step 1/6: Termux packages update ho rahe hain (thoda time lagega)"
export DEBIAN_FRONTEND=noninteractive
pkg update -y -o Dpkg::Options::="--force-confold" || true
pkg upgrade -y -o Dpkg::Options::="--force-confold" || die "pkg upgrade fail hua. Internet check kar ya 'termux-change-repo' chala."

# 2. Required packages
say "Step 2/6: Zaroori packages install ho rahe hain"
pkg install -y nodejs-lts tar curl git || die "nodejs-lts/tar/curl/git install nahi hue."
pkg install -y glibc-repo || die "glibc-repo install nahi hua."
pkg install -y glibc-runner || die "glibc-runner install nahi hua."

node --version >/dev/null 2>&1 || die "Node chal nahi raha. 'pkg upgrade -y' dobara chala kar dekh."
command -v grun >/dev/null 2>&1 || die "grun (glibc-runner) nahi mila."

# 3. Purani galat settings / broken links saaf
say "Step 3/6: Purani galat settings saaf ho rahi hain"
npm config delete os >/dev/null 2>&1 || true
rm -f "$PREFIX/bin/opencode"
npm uninstall -g opencode-ai >/dev/null 2>&1 || true

# 4. Download Linux arm64 binary
say "Step 4/6: Main file download ho rahi hai (~80 MB)"
WORK="$(mktemp -d "${TMPDIR:-$PREFIX/tmp}/db.XXXXXX")" || die "Temp folder nahi bana."
trap 'rm -rf "$WORK"' EXIT
cd "$WORK" || die "Temp folder me ja nahi paya."

OC_VER="$(npm view opencode-linux-arm64 version 2>/dev/null)"
[ -n "$OC_VER" ] || die "Version nahi mila. Internet check kar."
echo "Version: $OC_VER"

npm pack "opencode-linux-arm64@$OC_VER" >/dev/null 2>&1 || die "Download fail hua. Internet check kar aur dobara chala."
tar xzf "opencode-linux-arm64-$OC_VER.tgz" || die "Extract fail hua."
[ -f package/bin/opencode ] || die "Binary package me nahi mili."

mkdir -p "$HOME/.opencode/bin"
mv -f package/bin/opencode "$HOME/.opencode/bin/opencode-linux"
chmod +x "$HOME/.opencode/bin/opencode-linux"

# 5. Launcher
say "Step 5/6: 'opencode' command ban rahi hai"
cat > "$PREFIX/bin/opencode" <<EOF
#!$PREFIX/bin/sh
exec grun "\$HOME/.opencode/bin/opencode-linux" "\$@"
EOF
chmod +x "$PREFIX/bin/opencode"

# Auto-update band (update setup ko tod sakta hai)
CFG_DIR="$HOME/.config/opencode"
if [ ! -f "$CFG_DIR/opencode.json" ]; then
  mkdir -p "$CFG_DIR"
  printf '{\n  "autoupdate": false\n}\n' > "$CFG_DIR/opencode.json"
fi

# 6. Verify
say "Step 6/6: Check ho raha hai"
cd "$HOME" || true
VER="$(opencode --version 2>&1)" || die "opencode nahi chala. Output: $VER"

printf '\n\033[1;36m  ============================================\033[0m\n'
printf '\033[1;32m   INSTALL COMPLETE  (version %s)\033[0m\n' "$VER"
printf '\033[1;36m  ============================================\033[0m\n'
printf '\033[1;33m   Welcome to DANIEL BYPASS\033[0m\n'
printf '\033[1;33m   Owner : Mr. Deependra Ji (Rupandehi Mobile)\033[0m\n'
printf '\033[1;36m  ============================================\033[0m\n'
cat <<'MSG'

Ab chalane ke liye:
  cd ~            (ya apne project folder me)
  opencode

Pehli baar andar jaake  /connect  likh, provider chun, aur apni API key daal.
MSG

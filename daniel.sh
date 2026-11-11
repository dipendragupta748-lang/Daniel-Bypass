#!/data/data/com.termux/files/usr/bin/bash
# =====================================================================
#  DANIEL BYPASS - Termux Setup (Android, arm64)
#  Owner : Mr. Deependra Ji (Rupandehi Mobile)
#
#  Full setup  : bash <(curl -s https://raw.githubusercontent.com/dipendragupta748-lang/Daniel-Bypass/refs/heads/main/daniel.sh)
#  APK-only    : bash <(curl -s https://raw.githubusercontent.com/dipendragupta748-lang/Daniel-Bypass/refs/heads/main/daniel.sh) --apk-only
#
#  Re-run safe: jo step ho chuka hai wo skip hota hai.
#  Pura dobara karna ho:  rm -rf ~/.daniel/done
# =====================================================================

set -u

APK_ONLY=0
USER_NAME="${DANIEL_NAME:-}"
while [ $# -gt 0 ]; do
  case "$1" in
    --apk-only) APK_ONLY=1 ;;
    --name) shift; USER_NAME="${1:-}" ;;
  esac
  shift
done

DB_HOME="$HOME/.daniel"
DONE="$DB_HOME/done"
mkdir -p "$DONE"

ANDROID_HOME="$HOME/android-sdk"
JAVA_HOME_DIR="$PREFIX/lib/jvm/java-17-openjdk"
FAILED=()

say()  { printf '\n\033[1;32m==> %s\033[0m\n' "$*"; }
warn() { printf '\033[1;31m[!] %s\033[0m\n' "$*"; }

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
  printf '\033[0m\033[1;33m   Owner : Mr. Deependra Ji\n           (Rupandehi Mobile)\033[0m\n'
  printf '\033[1;36m  ============================================\033[0m\n\n'
}

run_step() {
  local id="$1" label="$2" fn="$3"
  if [ -f "$DONE/$id" ]; then
    say "$label  (pehle ho chuka, skip)"
    return 0
  fi
  say "$label"
  if "$fn"; then
    touch "$DONE/$id"
  else
    FAILED+=("$label")
    warn "FAIL: $label"
  fi
}

export DEBIAN_FRONTEND=noninteractive
export JAVA_HOME="$JAVA_HOME_DIR"
export ANDROID_HOME ANDROID_SDK_ROOT="$ANDROID_HOME"
export PATH="$JAVA_HOME/bin:$ANDROID_HOME/cmdline-tools/latest/bin:$PATH"

# ---------------------------------------------------------------------
banner
[ -n "${PREFIX:-}" ] && [ -d "$PREFIX" ] || { warn "Ye script Termux ke andar chalani hai."; exit 1; }
case "$(uname -m)" in
  aarch64|arm64) ;;
  *) warn "Ye script sirf arm64 phone ke liye hai ($(uname -m) mila)."; exit 1 ;;
esac

# Naam (banner ke liye) - sirf full setup me
if [ "$APK_ONLY" -eq 0 ]; then
  if [ -z "$USER_NAME" ]; then
    if [ -r /dev/tty ]; then
      printf 'Terminal banner ke liye apna naam likho (Enter = Daniel): '
      read -r USER_NAME </dev/tty || USER_NAME=""
    fi
  fi
  USER_NAME="$(printf '%s' "${USER_NAME:-Daniel}" | tr -cd 'A-Za-z0-9 ._-')"
  [ -n "$USER_NAME" ] || USER_NAME="Daniel"
  printf '%s\n' "$USER_NAME" > "$DB_HOME/name"
fi

# ---------------------------------------------------------------------
step_mirror() {
  local m="$PREFIX/etc/termux/mirrors/default"
  [ -e "$m" ] && ln -sfn "$m" "$PREFIX/etc/termux/chosen_mirrors"
  return 0
}

step_update() {
  pkg update -y -o Dpkg::Options::="--force-confold" || \
  { sleep 3; pkg update -y -o Dpkg::Options::="--force-confold"; } || return 1
  pkg upgrade -y -o Dpkg::Options::="--force-confold" || return 1
}

step_base() {
  pkg install -y curl git wget unzip zip tar || return 1
}

step_java() {
  pkg install -y openjdk-17 gradle aapt2 || return 1
  pkg install -y apksigner || warn "apksigner install nahi hua (zaroori nahi)."
  "$JAVA_HOME/bin/java" -version >/dev/null 2>&1 || return 1
}

step_sdk() {
  mkdir -p "$ANDROID_HOME"
  local tmp; tmp="$(mktemp -d "${TMPDIR:-$PREFIX/tmp}/sdk.XXXXXX")" || return 1
  if [ ! -x "$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager" ]; then
    curl -fL -o "$tmp/cmd.zip" \
      "https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip" || { rm -rf "$tmp"; return 1; }
    unzip -q "$tmp/cmd.zip" -d "$tmp" || { rm -rf "$tmp"; return 1; }
    mkdir -p "$ANDROID_HOME/cmdline-tools"
    rm -rf "$ANDROID_HOME/cmdline-tools/latest"
    mv "$tmp/cmdline-tools" "$ANDROID_HOME/cmdline-tools/latest" || { rm -rf "$tmp"; return 1; }
  fi
  rm -rf "$tmp"
  yes | sdkmanager --sdk_root="$ANDROID_HOME" --licenses >/dev/null 2>&1
  sdkmanager --sdk_root="$ANDROID_HOME" "platforms;android-35" "build-tools;34.0.0" || return 1
  [ -f "$ANDROID_HOME/platforms/android-35/android.jar" ] || return 1
}

step_gradle_props() {
  mkdir -p "$HOME/.gradle"
  local f="$HOME/.gradle/gradle.properties"
  touch "$f"
  sed -i '/^android.aapt2FromMavenOverride=/d;/^org.gradle.jvmargs=/d;/^kotlin.daemon.jvmargs=/d' "$f"
  {
    echo "android.aapt2FromMavenOverride=$PREFIX/bin/aapt2"
    echo "org.gradle.jvmargs=-Xmx1536m -Dfile.encoding=UTF-8"
    echo "kotlin.daemon.jvmargs=-Xmx1024m"
  } >> "$f"
}

step_addwrapper() {
  cat > "$PREFIX/bin/addwrapper" <<'EOF'
#!/data/data/com.termux/files/usr/bin/bash
# Current folder me gradlew daalta hai (Gradle 8.9)
set -e
T="$(mktemp -d "${TMPDIR:-$PREFIX/tmp}/gw.XXXXXX")"
touch "$T/settings.gradle"
( cd "$T" && gradle wrapper --gradle-version 8.9 --distribution-type bin --no-daemon -q )
cp "$T/gradlew" "$T/gradlew.bat" .
mkdir -p gradle/wrapper
cp "$T/gradle/wrapper/"* gradle/wrapper/
chmod +x gradlew
rm -rf "$T"
echo "gradlew add ho gaya."
EOF
  chmod +x "$PREFIX/bin/addwrapper"
}

step_opencode() {
  pkg install -y nodejs-lts glibc-repo || return 1
  pkg install -y glibc-runner || return 1
  command -v grun >/dev/null 2>&1 || return 1
  npm config delete os >/dev/null 2>&1 || true
  rm -f "$PREFIX/bin/opencode"
  npm uninstall -g opencode-ai >/dev/null 2>&1 || true

  local work ver
  work="$(mktemp -d "${TMPDIR:-$PREFIX/tmp}/oc.XXXXXX")" || return 1
  ( cd "$work" || exit 1
    ver="$(npm view opencode-linux-arm64 version 2>/dev/null)"
    [ -n "$ver" ] || exit 1
    npm pack "opencode-linux-arm64@$ver" >/dev/null 2>&1 || exit 1
    tar xzf "opencode-linux-arm64-$ver.tgz" || exit 1
    [ -f package/bin/opencode ] || exit 1
    mkdir -p "$HOME/.opencode/bin"
    mv -f package/bin/opencode "$HOME/.opencode/bin/opencode-linux"
    chmod +x "$HOME/.opencode/bin/opencode-linux"
  ) || { rm -rf "$work"; return 1; }
  rm -rf "$work"

  cat > "$PREFIX/bin/opencode" <<EOF
#!$PREFIX/bin/sh
exec grun "\$HOME/.opencode/bin/opencode-linux" "\$@"
EOF
  chmod +x "$PREFIX/bin/opencode"

  local cfg="$HOME/.config/opencode"
  if [ ! -f "$cfg/opencode.json" ]; then
    mkdir -p "$cfg"
    printf '{\n  "autoupdate": false\n}\n' > "$cfg/opencode.json"
  fi
  opencode --version >/dev/null 2>&1 || return 1
}

step_shell() {
  pkg install -y zsh || return 1
  [ -d "$HOME/.powerlevel10k" ] || \
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$HOME/.powerlevel10k" || return 1

  # Font (icons ke liye)
  mkdir -p "$HOME/.termux"
  if [ ! -f "$HOME/.termux/font.ttf" ]; then
    curl -fL -o "$HOME/.termux/font.ttf" \
      "https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Regular.ttf" \
      || warn "Font download nahi hua (zaroori nahi)."
  fi

  # Rainbow banner
  cat > "$DB_HOME/banner.sh" <<'EOF'
_db_color() {
  case $(( $1 % 7 )) in
    0) echo 196;; 1) echo 208;; 2) echo 226;; 3) echo 46;; 4) echo 51;; 5) echo 33;; 6) echo 129;;
  esac
}
daniel_banner() {
  local name i=0 line
  name="$(cat "$HOME/.daniel/name" 2>/dev/null)"
  [ -n "$name" ] || name="Daniel"
  while IFS= read -r line; do
    printf '\033[1;38;5;%sm%s\033[0m\n' "$(_db_color $i)" "$line"
    i=$((i+1))
  done <<'ART'
 ____    _    _   _ ___ _____ _
|  _ \  / \  | \ | |_ _| ____| |
| | | |/ _ \ |  \| || ||  _| | |
| |_| / ___ \| |\  || || |___| |___
|____/_/   \_\_| \_|___|_____|_____|
        B  Y  P  A  S  S
ART
  printf '\033[1;33m  Welcome back, %s!\033[0m\n' "$name"
  printf '\033[1;36m  Owner: Mr. Deependra Ji (Rupandehi Mobile)\033[0m\n\n'
}
EOF

  # Minimal p10k look (p10k configure se badal sakte ho)
  if [ ! -f "$HOME/.p10k.zsh" ]; then
    cat > "$HOME/.p10k.zsh" <<'EOF'
typeset -g POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(dir vcs newline prompt_char)
typeset -g POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(status command_execution_time time)
typeset -g POWERLEVEL9K_PROMPT_CHAR_OK_{VIINS,VICMD,VIVIS,VIOWR}_FOREGROUND=46
typeset -g POWERLEVEL9K_PROMPT_CHAR_ERROR_{VIINS,VICMD,VIVIS,VIOWR}_FOREGROUND=196
typeset -g POWERLEVEL9K_DIR_FOREGROUND=39
EOF
  fi

  local common
  common='export JAVA_HOME="'"$JAVA_HOME_DIR"'"
export ANDROID_HOME="$HOME/android-sdk"
export ANDROID_SDK_ROOT="$ANDROID_HOME"
export PATH="$JAVA_HOME/bin:$ANDROID_HOME/cmdline-tools/latest/bin:$PATH"
alias c="clear"
alias update="pkg update -y && pkg upgrade -y"
alias coding="mkdir -p /sdcard/coding && cd /sdcard/coding"
. "$HOME/.daniel/banner.sh"
daniel_banner'

  # .zshrc
  touch "$HOME/.zshrc"
  sed -i '/# >>> daniel >>>/,/# <<< daniel <<</d' "$HOME/.zshrc"
  {
    echo '# >>> daniel >>>'
    echo 'typeset -g POWERLEVEL9K_INSTANT_PROMPT=off'
    echo 'typeset -g POWERLEVEL9K_DISABLE_CONFIGURATION_WIZARD=true'
    echo 'source "$HOME/.powerlevel10k/powerlevel10k.zsh-theme"'
    echo '[[ -f "$HOME/.p10k.zsh" ]] && source "$HOME/.p10k.zsh"'
    echo "$common"
    echo '# <<< daniel <<<'
  } >> "$HOME/.zshrc"

  # .bashrc (backup)
  touch "$HOME/.bashrc"
  sed -i '/# >>> daniel >>>/,/# <<< daniel <<</d' "$HOME/.bashrc"
  {
    echo '# >>> daniel >>>'
    echo "$common"
    echo '# <<< daniel <<<'
  } >> "$HOME/.bashrc"

  chsh -s zsh >/dev/null 2>&1 || true
  command -v termux-reload-settings >/dev/null 2>&1 && termux-reload-settings || true
}

step_testapp() {
  local P="$HOME/hello-daniel"
  mkdir -p "$P/app/src/main/java/com/daniel/hello"

  cat > "$P/settings.gradle.kts" <<'EOF'
pluginManagement {
    repositories { google(); mavenCentral(); gradlePluginPortal() }
}
dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories { google(); mavenCentral() }
}
rootProject.name = "hello-daniel"
include(":app")
EOF

  cat > "$P/build.gradle.kts" <<'EOF'
plugins {
    id("com.android.application") version "8.6.1" apply false
    id("org.jetbrains.kotlin.android") version "2.0.20" apply false
}
EOF

  cat > "$P/gradle.properties" <<'EOF'
android.useAndroidX=false
android.nonTransitiveRClass=true
EOF

  cat > "$P/app/build.gradle.kts" <<'EOF'
plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
}

android {
    namespace = "com.daniel.hello"
    compileSdk = 35

    defaultConfig {
        applicationId = "com.daniel.hello"
        minSdk = 24
        targetSdk = 35
        versionCode = 1
        versionName = "1.0"
    }
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    kotlinOptions { jvmTarget = "17" }
}
EOF

  cat > "$P/app/src/main/AndroidManifest.xml" <<'EOF'
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <application
        android:label="Hello Daniel"
        android:theme="@android:style/Theme.DeviceDefault.Light">
        <activity android:name=".MainActivity" android:exported="true">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>
    </application>
</manifest>
EOF

  cat > "$P/app/src/main/java/com/daniel/hello/MainActivity.kt" <<'EOF'
package com.daniel.hello

import android.app.Activity
import android.graphics.Color
import android.os.Bundle
import android.view.Gravity
import android.widget.TextView

class MainActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val tv = TextView(this)
        tv.text = "Ye app phone pe hi bana hai!"
        tv.textSize = 24f
        tv.setTextColor(Color.BLACK)
        tv.gravity = Gravity.CENTER
        setContentView(tv)
    }
}
EOF

  ( cd "$P" || exit 1
    addwrapper || exit 1
    ./gradlew assembleDebug --no-daemon || exit 1
  ) || return 1

  local apk="$P/app/build/outputs/apk/debug/app-debug.apk"
  [ -f "$apk" ] || return 1
  if [ -d /sdcard/Download ] && [ -w /sdcard/Download ]; then
    cp "$apk" /sdcard/Download/hello-daniel.apk && echo "APK: Download/hello-daniel.apk"
  else
    warn "Storage permission nahi mili. APK yaha hai: $apk"
  fi
}

verify_android() {
  local ok=1
  "$JAVA_HOME/bin/java" -version >/dev/null 2>&1 || ok=0
  [ -f "$ANDROID_HOME/platforms/android-35/android.jar" ] || ok=0
  [ -x "$PREFIX/bin/aapt2" ] || ok=0
  grep -q '^android.aapt2FromMavenOverride=' "$HOME/.gradle/gradle.properties" 2>/dev/null || ok=0
  [ "$ok" -eq 1 ]
}

# ---------------------------------------------------------------------
if [ "$APK_ONLY" -eq 0 ]; then
  command -v termux-setup-storage >/dev/null 2>&1 && \
    { [ -d /sdcard/Download ] || termux-setup-storage; sleep 2; }
fi

run_step mirror   "Step 1: Mirror set ho raha hai"          step_mirror
run_step update   "Step 2: Termux update/upgrade (thoda time)" step_update
run_step base     "Step 3: Basic tools"                      step_base
run_step java     "Step 4: Java 17 + Gradle + aapt2"         step_java
run_step sdk      "Step 5: Android SDK 35"                   step_sdk
run_step gprops   "Step 6: Gradle settings"                  step_gradle_props
run_step wrapper  "Step 7: addwrapper command"               step_addwrapper

if [ "$APK_ONLY" -eq 0 ]; then
  run_step opencode "Step 8: OpenCode (glibc-runner)"        step_opencode
  run_step shell    "Step 9: zsh + p10k + banner + aliases"  step_shell
  run_step testapp  "Step 10: Test app (hello-daniel.apk)"   step_testapp
fi

# ---------------------------------------------------------------------
printf '\n\033[1;36m  ============================================\033[0m\n'
if [ "${#FAILED[@]}" -gt 0 ]; then
  printf '\033[1;31m   Ye steps fail hue:\033[0m\n'
  for f in "${FAILED[@]}"; do printf '\033[1;31m    - %s\033[0m\n' "$f"; done
  printf '\033[1;33m   Dobara wahi command chalao, jo ho chuka wo skip hoga.\033[0m\n'
else
  printf '\033[1;32m   DANIEL BYPASS SETUP COMPLETE\033[0m\n'
fi
printf '\033[1;33m   Owner : Mr. Deependra Ji (Rupandehi Mobile)\033[0m\n'
printf '\033[1;36m  ============================================\033[0m\n'

if verify_android; then
  echo "ANDROID_SETUP_OK"
else
  warn "ANDROID_SETUP_OK nahi aaya: upar ke fail hue step dekho."
fi

[ "$APK_ONLY" -eq 0 ] && echo && echo "Ab Termux band karke dobara kholo."
[ "${#FAILED[@]}" -eq 0 ]

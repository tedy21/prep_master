#!/usr/bin/env bash
# Install Flutter SDK outside snap (fixes Gradle "cannot start flutter process" on Linux).
set -euo pipefail

FLUTTER_DIR="${FLUTTER_DIR:-$HOME/flutter/flutter_linux_3.29.0-stable/flutter}"

if [[ ! -x "$FLUTTER_DIR/bin/flutter" ]]; then
  FLUTTER_DIR="${FLUTTER_DIR:-$HOME/flutter}"
  if [[ ! -d "$FLUTTER_DIR/.git" ]]; then
    echo "==> Cloning Flutter SDK to $FLUTTER_DIR"
    git clone https://github.com/flutter/flutter.git -b stable --depth 1 "$FLUTTER_DIR"
  else
    echo "==> Updating existing Flutter SDK at $FLUTTER_DIR"
    git -C "$FLUTTER_DIR" pull
  fi
else
  echo "==> Using Flutter SDK at $FLUTTER_DIR"
fi

export PATH="$FLUTTER_DIR/bin:$PATH"
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
LOCAL_PROPS="$PROJECT_DIR/android/local.properties"

flutter --version
flutter doctor

echo "==> Updating android/local.properties"
mkdir -p "$(dirname "$LOCAL_PROPS")"
if [[ -f "$LOCAL_PROPS" ]]; then
  # Replace or append flutter.sdk
  if grep -q '^flutter.sdk=' "$LOCAL_PROPS"; then
    sed -i "s|^flutter.sdk=.*|flutter.sdk=$FLUTTER_DIR|" "$LOCAL_PROPS"
  else
    echo "flutter.sdk=$FLUTTER_DIR" >> "$LOCAL_PROPS"
  fi
else
  cat > "$LOCAL_PROPS" <<EOF
sdk.dir=$HOME/Android/Sdk
flutter.sdk=$FLUTTER_DIR
EOF
fi

echo ""
echo "Done. Add this to your ~/.bashrc:"
echo '  export PATH="$HOME/flutter/bin:$PATH"'
echo ""
echo "Then from the project root:"
echo "  cd $PROJECT_DIR"
echo "  flutter clean && flutter pub get && flutter run"

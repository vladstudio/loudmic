#!/bin/bash
set -e
cd "$(dirname "$0")"
source ../mac-scripts/build-kit.sh
build_app "LoudMic" \
  --info app/LoudMic/Info.plist \
  --resources "AppIcon.icns"

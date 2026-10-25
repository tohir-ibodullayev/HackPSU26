#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
if ! command -v swiftc >/dev/null 2>&1; then
  echo 'Model checks require Swift (on macOS, install Xcode 15+).' >&2
  exit 1
fi
if [ "$(uname -s)" != Darwin ]; then
  echo 'AppModel uses SwiftUI and Combine; run these checks on macOS.' >&2
  exit 1
fi
check_dir=$(mktemp -d)
trap 'rm -rf "$check_dir"' EXIT
swiftc -parse-as-library -target "$(uname -m)-apple-macosx13.0" \
  Studyday/Models/Models.swift \
  Studyday/Services/ServiceProtocols.swift \
  Studyday/Services/MockServices.swift \
  Studyday/Services/AppModel.swift \
  Studyday/Services/GroqBuddyService.swift \
  Tests/CampusMateChecks.swift -o "$check_dir/campusmate-checks"
"$check_dir/campusmate-checks"

#!/usr/bin/env bash
set -euo pipefail

if ! command -v swiftlint >/dev/null 2>&1; then
  echo "error: SwiftLint not installed. Install via Homebrew (brew install swiftlint) or Mint before running." >&2
  exit 1
fi

swiftlint lint --strict "$@"

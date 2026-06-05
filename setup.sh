#!/usr/bin/env bash
set -euo pipefail

python3 -m venv .venv
source .venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt

echo ""
echo "Python env ready (model conversion + evaluation)."
echo "Build the Swift app:  swift build"
echo "Run it:               swift run"
echo "On first run, grant Camera, Microphone, and Speech Recognition in"
echo "System Settings > Privacy & Security, then re-run."

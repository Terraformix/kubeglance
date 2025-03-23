#!/bin/bash

REPORT_DIR="$(pwd)/gitleaks-reports"
REPORT_FILE="$REPORT_DIR/gitleaks-report.json"

# Ensure the directory exists
mkdir -p "$REPORT_DIR"

echo "🔍 Running Gitleaks scan..."
docker run --rm -v "$REPORT_DIR:/workspace" -v "$(pwd):/source" zricethezav/gitleaks:latest detect --source="/source" \
    --no-git --report-path="/workspace/gitleaks-report.json" --report-format=json

# Debugging: Check if the report file exists inside the container
echo "📂 Checking if Gitleaks report exists..."
docker run --rm -v "$REPORT_DIR:/workspace" alpine ls -lah /workspace

# # Check if the scan report exists
# if [[ ! -f "$REPORT_FILE" ]]; then
#     echo "❌ Error: Gitleaks report file not found!"
#     exit 1
# fi

# Extract number of leaks found using jq
LEAK_COUNT=$(jq '. | length' "$REPORT_FILE")

echo "🔎 Found $LEAK_COUNT secrets."

THRESHOLD=0

if [[ "$LEAK_COUNT" -gt "$THRESHOLD" ]]; then
    echo "❌ Secret leak threshold exceeded! ($LEAK_COUNT found, allowed: $THRESHOLD)"
    exit 1
else
    echo "✅ Secret scanning passed. ($LEAK_COUNT found, allowed: $THRESHOLD)"
    exit 0
fi

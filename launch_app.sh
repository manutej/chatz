#!/bin/bash

# Chatz App Launch Script
# This script launches the Chatz Flutter app in Chrome

echo "🚀 Launching Chatz App..."
echo ""

# Navigate to project directory
cd "$(dirname "$0")"

# Check if Flutter is available
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter not found in PATH"
    echo "Using direct path..."
    FLUTTER="$HOME/development/flutter/bin/flutter"
else
    FLUTTER="flutter"
fi

# Kill any existing Flutter processes
echo "🧹 Cleaning up old processes..."
pkill -f "flutter run" 2>/dev/null || true

# Run the app
echo "▶️  Starting app in Chrome..."
echo ""
$FLUTTER run -d chrome

echo ""
echo "✅ App closed"

#!/bin/bash

# Build and Run Dynamic Island
# This script builds the Dynamic Island app and runs it

set -e

echo "🏝️  Building Dynamic Island..."

# Navigate to the project directory
cd "$(dirname "$0")"

# Build the project
swift build -c release

echo "✅ Build complete!"
echo "🚀 Launching Dynamic Island..."

# Run the app
./.build/release/DynamicIsland &

echo "🏝️  Dynamic Island is now running!"
echo "📍 Look for the island at the top of your screen near the notch"
echo "🖱️  Hover over it to expand"
echo "📱 Right-click the status bar icon (🏝️) for options"
echo ""
echo "To quit: Right-click the 🏝️ icon in the status bar and select Quit"

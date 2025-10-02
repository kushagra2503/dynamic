#!/bin/bash

# Test script to verify battery monitoring functionality
# This script will build and run the Dynamic Island app and show battery info

set -e

echo "🔋 Testing Dynamic Island Charging Detection"
echo "=============================================="

# Navigate to the project directory
cd "$(dirname "$0")"

echo "📱 Building Dynamic Island..."
swift build -c release

echo "✅ Build complete!"
echo ""
echo "🔋 Current Battery Status:"
echo "-------------------------"

# Use system_profiler to show current battery info
system_profiler SPPowerDataType | grep -E "(Charge|Charging|Battery|Condition|Cycle)"

echo ""
echo "🚀 Starting Dynamic Island..."
echo "📍 The island will automatically expand when you plug/unplug your charger"
echo "🔌 Try plugging in your charger to see the charging indicator!"
echo "⏰ Charging status will show for 5 seconds when plugged in"
echo ""
echo "🧪 Expected Behavior:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ PLUG IN CHARGER:"
echo "   → Island auto-expands and shows: ⚡ Charging  🔋 85%  2h 34m"
echo "   → Auto-collapses after 5 seconds (unless hovering)"
echo ""
echo "✅ MANUAL HOVER (while charging):"
echo "   → Island expands but shows minimal content (just a dot)"
echo "   → Does NOT show charging info (that's only for auto-expansion)"
echo ""
echo "✅ UNPLUG CHARGER:"
echo "   → Island auto-collapses immediately"
echo "   → No charging indicator when collapsed"
echo ""
echo "✅ MANUAL HOVER (when not charging):"
echo "   → Island expands and shows minimal content"
echo "   → Collapses when you move mouse away"
echo ""
echo "🎯 Key Point: Charging info only appears during automatic"
echo "   expansion when you plug/unplug, NOT during manual hover!"
echo ""

# Run the app
./.build/release/DynamicIsland &

APP_PID=$!
echo "🏝️ Dynamic Island started with PID: $APP_PID"
echo "📝 To stop: kill $APP_PID or use menu bar quit option"

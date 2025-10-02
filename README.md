# 🏝️ Dynamic Island for macOS

A stunning recreation of Apple's Dynamic Island for your MacBook Pro, featuring **automatic notch detection** and **real-time charging status** just like iOS!

## ✨ Features

### 🎯 **Automatic Notch Detection**
- **Perfect size matching** - Automatically detects your MacBook Pro model (14" or 16")
- **Precise positioning** - Collapses perfectly over your actual notch
- **Smart fallback** - Works on non-notch Macs with elegant top-center placement
- **Multi-monitor support** - Automatically repositions when switching displays

### 🔋 **Live Charging Status** (NEW!)
- **Auto-expand on charging** - Automatically shows when you plug in your charger
- **Battery percentage** - Real-time battery level display
- **Charging time** - Shows estimated time to full charge
- **Visual battery indicator** - Animated battery icon with fill level
- **Auto-hide** - Collapses after 5 seconds (unless you're hovering)

### 🎨 **Beautiful Animations**
- **Smooth expand/collapse** - Fluid spring animations
- **Hover interactions** - Expands on hover, collapses when you move away
- **No jittery behavior** - Stays perfectly still when expanded
- **Charging animations** - Special animations when plugging/unplugging

### ⚡ **Performance**
- **Minimal CPU usage** - Efficient battery monitoring and animations
- **Memory optimized** - Smart caching of notch measurements
- **Background friendly** - Runs quietly in the background

## 🚀 Quick Start

### Option 1: Easy Launch Script
```bash
./build_and_run.sh
```

### Option 2: Manual Build
```bash
swift build -c release
./.build/release/DynamicIsland
```

### Option 3: Test Charging Features
```bash
./test_charging.sh
```

## 🔌 Charging Features Demo

1. **Plug in your charger** - Watch the Dynamic Island automatically expand and show:
   - ⚡ Green charging bolt icon
   - 🔋 Current battery percentage  
   - ⏰ Time remaining to full charge
   - 📊 Visual battery level indicator

2. **Unplug your charger** - The island will automatically collapse

3. **Hover while charging** - Get detailed charging information

## 🎛️ Controls

- **Hover** - Expand the Dynamic Island
- **Click** - Manual expand/collapse toggle
- **Menu Bar** - Right-click the 🏝️ icon for options:
  - Reposition Island
  - Quit

## 📱 What It Shows

### When Charging:
```
⚡ Charging    🔋 85%
   2h 34m      ████████░░
```

### When Collapsed & Charging:
```
⚡ 85%
```

### When Not Charging:
- Minimal dot indicator when expanded
- Completely invisible when collapsed

## 🔧 Technical Details

### Supported Devices
- ✅ **MacBook Pro 14"** (2021, 2023) - Native notch support
- ✅ **MacBook Pro 16"** (2021, 2023) - Native notch support  
- ✅ **Other Macs** - Top-center positioning fallback

### System Requirements
- macOS 13.0+ (Ventura or later)
- Swift 5.9+
- Xcode Command Line Tools

### Architecture
- **NotchDetector.swift** - Automatic notch size detection and positioning
- **BatteryMonitor.swift** - Real-time battery and charging status monitoring
- **DynamicIslandView.swift** - SwiftUI interface with smooth animations
- **AppDelegate.swift** - Window management and system integration

## 🎨 Customization

The Dynamic Island automatically adapts to:
- Your specific MacBook model's notch size
- Charging state changes
- Screen resolution and safe areas
- Multi-monitor setups

## 🐛 Troubleshooting

### Island Not Positioning Correctly?
```bash
# Right-click menu bar icon → "Reposition Island"
# Or restart the app
./build_and_run.sh
```

### Charging Status Not Showing?
- Ensure you're on a MacBook with battery
- Try unplugging and replugging your charger
- Check System Preferences → Battery permissions

### Build Issues?
```bash
# Clean build
rm -rf .build
swift build -c release
```

## 🔒 Privacy & Permissions

- **No network access** - All functionality is local
- **No data collection** - Your battery info stays on your Mac
- **System integration only** - Uses standard macOS APIs for battery monitoring

## ⚙️ Advanced Usage

### Monitor Battery in Terminal
```bash
# Watch real-time battery changes
system_profiler SPPowerDataType | grep -E "(Charge|Charging)"
```

### Debug Mode
```bash
# See detailed charging events in console
swift run
# Then plug/unplug charger to see debug output
```

## 🎯 Roadmap

- [ ] **Custom content** - Add your own widgets and information
- [ ] **Notification integration** - Show system notifications
- [ ] **Activity monitoring** - CPU, memory usage indicators  
- [ ] **Calendar events** - Show upcoming meetings
- [ ] **Music controls** - Now playing information

## 📋 Changelog

### v2.0 - Charging Features
- ✅ Added real-time charging status detection
- ✅ Auto-expand on charger plug/unplug
- ✅ Battery percentage and time remaining
- ✅ Visual battery level indicator
- ✅ Improved animation stability

### v1.0 - Initial Release  
- ✅ Automatic notch detection for MacBook Pro 14"/16"
- ✅ Smooth hover expand/collapse animations
- ✅ Perfect notch size matching
- ✅ Multi-monitor support

## 🤝 Contributing

Found a bug or want to add features? 
1. Fork the repository
2. Make your changes  
3. Test on both 14" and 16" MacBook Pros if possible
4. Submit a pull request

## 📄 License

MIT License - Feel free to use and modify!

---

**Made with ❤️ for MacBook Pro users who miss the iPhone's Dynamic Island**

*Works best on MacBook Pro 14" and 16" with notch, but supports all Macs!*
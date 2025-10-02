import Cocoa
import IOKit.ps
import Foundation

class BatteryMonitor: ObservableObject {
    @Published var isCharging = false
    @Published var batteryLevel: Int = 0
    @Published var isPluggedIn = false
    @Published var chargingState: ChargingState = .unknown

    private var timer: Timer?
    private var lastChargingState: Bool = false
    private var lastPluggedState: Bool = false

    enum ChargingState {
        case charging
        case notCharging
        case fullyCharged
        case unknown

        var displayString: String {
            switch self {
            case .charging: return "Charging"
            case .notCharging: return "On Battery"
            case .fullyCharged: return "Charged"
            case .unknown: return "Unknown"
            }
        }

        var systemImageName: String {
            switch self {
            case .charging: return "bolt.fill"
            case .notCharging: return "battery"
            case .fullyCharged: return "battery.100"
            case .unknown: return "battery.0"
            }
        }

        var rawValue: String {
            switch self {
            case .charging: return "charging"
            case .notCharging: return "notCharging"
            case .fullyCharged: return "fullyCharged"
            case .unknown: return "unknown"
            }
        }
    }

    static let shared = BatteryMonitor()

    private init() {
        updateBatteryStatus()
        startPolling()
    }

    deinit {
        stopPolling()
    }

    private func startPolling() {
        // Poll every 2 seconds for battery changes
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.updateBatteryStatus()
        }
    }

    private func stopPolling() {
        timer?.invalidate()
        timer = nil
    }

    private func updateBatteryStatus() {
        guard let powerSources = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let sources = IOPSCopyPowerSourcesList(powerSources)?.takeRetainedValue() as? [CFTypeRef] else {
            return
        }

        for source in sources {
            guard let info = IOPSGetPowerSourceDescription(powerSources, source)?.takeUnretainedValue() as? [String: Any] else {
                continue
            }

            // Check if this is the internal battery
            guard let powerSourceState = info[kIOPSPowerSourceStateKey] as? String,
                  let transportType = info[kIOPSTransportTypeKey] as? String,
                  transportType == kIOPSInternalType else {
                continue
            }

            // Get battery level
            if let currentCapacity = info[kIOPSCurrentCapacityKey] as? Int,
               let maxCapacity = info[kIOPSMaxCapacityKey] as? Int {
                batteryLevel = Int((Double(currentCapacity) / Double(maxCapacity)) * 100)
            }

            // Determine charging state
            let wasCharging = isCharging
            let wasPluggedIn = isPluggedIn

            if powerSourceState == kIOPSACPowerValue {
                isPluggedIn = true

                // Check if actually charging or full
                if let isChargingValue = info[kIOPSIsChargingKey] as? Bool {
                    isCharging = isChargingValue
                    chargingState = isChargingValue ? .charging : .fullyCharged
                } else {
                    // Fallback: if plugged in and not at 100%, assume charging
                    isCharging = batteryLevel < 100
                    chargingState = batteryLevel < 100 ? .charging : .fullyCharged
                }
            } else {
                isPluggedIn = false
                isCharging = false
                chargingState = .notCharging
            }

            // Notify about charging state changes
            if wasCharging != isCharging || wasPluggedIn != isPluggedIn {
                DispatchQueue.main.async {
                    self.notifyChargingStateChanged(
                        wasCharging: wasCharging,
                        isCharging: self.isCharging,
                        wasPluggedIn: wasPluggedIn,
                        isPluggedIn: self.isPluggedIn
                    )
                }
            }

            break // We only care about the first (internal) battery
        }
    }

    private func notifyChargingStateChanged(wasCharging: Bool, isCharging: Bool, wasPluggedIn: Bool, isPluggedIn: Bool) {
        let userInfo: [String: Any] = [
            "wasCharging": wasCharging,
            "isCharging": isCharging,
            "wasPluggedIn": wasPluggedIn,
            "isPluggedIn": isPluggedIn,
            "batteryLevel": batteryLevel,
            "chargingState": chargingState.rawValue
        ]

        NotificationCenter.default.post(
            name: .batteryStateChanged,
            object: self,
            userInfo: userInfo
        )
    }

    // MARK: - Public Methods

    func getBatteryInfo() -> (level: Int, isCharging: Bool, isPluggedIn: Bool, state: ChargingState) {
        return (batteryLevel, isCharging, isPluggedIn, chargingState)
    }

    func getChargingTimeRemaining() -> String {
        guard isCharging else { return "Not charging" }

        guard let powerSources = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let sources = IOPSCopyPowerSourcesList(powerSources)?.takeRetainedValue() as? [CFTypeRef] else {
            return "Unknown"
        }

        for source in sources {
            guard let info = IOPSGetPowerSourceDescription(powerSources, source)?.takeUnretainedValue() as? [String: Any] else {
                continue
            }

            if let timeToFull = info[kIOPSTimeToFullChargeKey] as? Int {
                if timeToFull == -1 {
                    return "Calculating..."
                } else if timeToFull == 0 {
                    return "Fully charged"
                } else {
                    let hours = timeToFull / 60
                    let minutes = timeToFull % 60

                    if hours > 0 {
                        return "\(hours)h \(minutes)m"
                    } else {
                        return "\(minutes)m"
                    }
                }
            }
            break
        }

        return "Unknown"
    }
}

// MARK: - Notification Extension
extension Notification.Name {
    static let batteryStateChanged = Notification.Name("batteryStateChanged")
}

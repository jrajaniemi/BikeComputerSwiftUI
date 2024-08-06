import Foundation
import UIKit

class BatteryManager: ObservableObject {
    static let shared = BatteryManager()
    
    @Published var batteryLevel: Float = UIDevice.current.batteryLevel
    @Published var isCharging: Bool = UIDevice.current.batteryState == .charging || UIDevice.current.batteryState == .full
    @Published var isIdleTimerDisabled: Bool = false
    private init() {
        UIDevice.current.isBatteryMonitoringEnabled = true
        NotificationCenter.default.addObserver(self, selector: #selector(batteryLevelDidChange), name: UIDevice.batteryLevelDidChangeNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(batteryStateDidChange), name: UIDevice.batteryStateDidChangeNotification, object: nil)
        updateBatteryStatus()
    }
    
    @objc private func batteryLevelDidChange(notification: NSNotification) {
        updateBatteryStatus()
    }
    
    @objc private func batteryStateDidChange(notification: NSNotification) {
        updateBatteryStatus()
    }
    
    private func updateBatteryStatus() {
        // Päivitetään suoraan UIDevice-objektista
        UIDevice.current.isBatteryMonitoringEnabled = true
        batteryLevel = UIDevice.current.batteryLevel
        isCharging = UIDevice.current.batteryState == .charging || UIDevice.current.batteryState == .full
#if DEBUG
        updateIdleTimer()
#endif
    }
    
    private func updateIdleTimer() {
        if isCharging && batteryLevel > 0.15 {
#if DEBUG
            print("Device is charging and battery level is above 15%. Keeping screen on.")
            print("isIdleTimerDisabled is now \(UIApplication.shared.isIdleTimerDisabled)")
#endif
            UIApplication.shared.isIdleTimerDisabled = true
            isIdleTimerDisabled = true
        } else {
#if DEBUG
            print("Device is not charging or battery level is 15% or below. Allowing screen to turn off.")
            print("isIdleTimerDisabled is now \(UIApplication.shared.isIdleTimerDisabled)")
#endif
            UIApplication.shared.isIdleTimerDisabled = false
            isIdleTimerDisabled = false
        }
    }
}

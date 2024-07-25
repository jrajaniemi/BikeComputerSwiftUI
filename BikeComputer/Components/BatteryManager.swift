import Foundation
import UIKit

class BatteryManager: ObservableObject {
    static let shared = BatteryManager()
    
    @Published var batteryLevel: Float = UIDevice.current.batteryLevel
    @Published var isCharging: Bool = UIDevice.current.batteryState == .charging || UIDevice.current.batteryState == .full
    
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
    }
}

//
//  ThemeManager.swift
//  BikeComputer
//
//  Created by Jussi Rajaniemi on 25.7.2024.
//

import Foundation
import SwiftUI

enum Theme {
    case light, dark
}

class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    @Published var currentTheme: Theme = .light
    
    func updateTheme(sunriseSunsetTimes: SunriseSunsetTimes) {
        let now = Date()
        if now >= sunriseSunsetTimes.sunrise && now < sunriseSunsetTimes.sunset {
            currentTheme = .light
        } else {
            currentTheme = .dark
        }
    }
}

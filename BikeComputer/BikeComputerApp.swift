//
//  BikeComputerApp.swift
//  BikeComputer
//
//  Created by Jussi Rajaniemi on 19.7.2024.
//

import SwiftUI

@main
struct BikeComputerApp: App {
    @AppStorage("selectedColorScheme") private var selectedColorScheme: Int = 0

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(colorScheme())
        }
        
    }
    private func colorScheme() -> ColorScheme? {
        switch selectedColorScheme {
        case 1:
            return .light
        case 2:
            return .dark
        default:
            return nil
        }
    }}

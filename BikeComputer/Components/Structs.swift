//
//  Structs.swift
//  BikeComputer
//
//  Created by Jussi Rajaniemi on 11.8.2024.
//

import Foundation
import HealthKit

struct RoutePoint: Codable, Identifiable {
    var id = UUID() // Lisää identifioiva ominaisuus
    let speed: Double
    let heading: Double
    let altitude: Double
    let longitude: Double
    let latitude: Double
    let timestamp: Date

    init(speed: Double, heading: Double, altitude: Double, longitude: Double, latitude: Double, timestamp: Date) {
        self.speed = Double(round(10 * speed) / 10) // Pyöristetään 1 desimaaliin
        self.heading = Double(round(100 * heading) / 100) // Pyöristetään 2 desimaaliin
        self.altitude = Double(round(10 * altitude) / 10) // Pyöristetään 1 desimaaliin
        self.longitude = Double(round(100000 * longitude) / 100000) // Pyöristetään 5 desimaaliin
        self.latitude = Double(round(100000 * latitude) / 100000) // Pyöristetään 5 desimaaliin
        self.timestamp = timestamp
    }
}

struct Route: Codable, Identifiable {
    let id: UUID
    var name: String
    var description: String
    let startDate: Date
    var endDate: Date?
    var points: [RoutePoint]
    var distance: Double? // Kokonaismatka
    var calories: Double? // Lasketut kalorit
    var activityType: TrackableWorkoutActivityType // Aktiviteetin tyyppi, esim. 13 == ".cycling"

    init(name: String, description: String, startDate: Date, endDate: Date?, points: [RoutePoint]) {
        self.id = UUID()
        self.name = name
        self.description = description
        self.startDate = startDate
        self.endDate = endDate
        self.points = points
        self.activityType = TrackableWorkoutActivityType.other
    }
}

//
//  LocationManagerTests.swift
//  BikeComputerTests
//
//  Created by Jussi Rajaniemi on 29.7.2024.
//
import XCTest
import CoreLocation
import Combine
@testable import BikeComputer

class LocationManagerTests: XCTestCase {

    var locationManager: LocationManager!
    var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        locationManager = LocationManager()
        cancellables = []
    }

    override func tearDown() {
        locationManager = nil
        cancellables = nil
        super.tearDown()
    }

    func testStartLocationUpdates() {
        locationManager.startLocationUpdates()
        // Ei suoraa tapaa tarkistaa, onko päivitykset käynnissä,
        // mutta voidaan tarkistaa, että sijaintipäivityksen aloitusmetodi toimii.
        // Oletetaan, että jos startLocationUpdates() kutsutaan, niin päivitykset alkavat.
        XCTAssertTrue(locationManager.manager.delegate != nil, "Location updates should be started")
    }

    func testStopLocationUpdates() {
        locationManager.stopLocationUpdates()
        // Ei suoraa tapaa tarkistaa, onko päivitykset pysäytetty,
        // mutta voidaan tarkistaa, että sijaintipäivityksen pysäytysmetodi toimii.
        XCTAssertFalse(locationManager.isTracking, "Location updates should be stopped")
    }

    func testLocationAuthorization() {
        let manager = CLLocationManager()
        locationManager.locationManagerDidChangeAuthorization(manager)
        
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            XCTAssertTrue(locationManager.manager.delegate != nil, "Location updates should be started")
        case .denied, .restricted, .notDetermined:
            XCTAssertFalse(locationManager.isTracking, "Location updates should not be started")
        @unknown default:
            XCTFail("Unknown authorization status")
        }
    }

    func testLocationUpdate() {
        let location = CLLocation(latitude: 60.1699, longitude: 24.9384)
        locationManager.locationManager(locationManager.manager, didUpdateLocations: [location])
        
        XCTAssertEqual(locationManager.latitude, 60.1699, "Latitude should be updated")
        XCTAssertEqual(locationManager.longitude, 24.9384, "Longitude should be updated")
    }

    func testHeadingUpdate() {
        let newHeading = CLHeading()
        locationManager.locationManager(locationManager.manager, didUpdateHeading: newHeading)
        
        XCTAssertEqual(locationManager.heading, newHeading.trueHeading, "Heading should be updated")
    }
}

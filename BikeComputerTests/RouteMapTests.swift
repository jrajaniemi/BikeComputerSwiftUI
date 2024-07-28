//
//  RouteMapTests.swift
//  BikeComputerTests
//
//  Created by Jussi Rajaniemi on 27.7.2024.
//

import XCTest
import CoreLocation
@testable import BikeComputer

final class RouteMapTests: XCTestCase {

    func testLinearInterpolation() {
            // Step 1: Prepare input data
            let points: [RoutePoint] = [
                RoutePoint(speed: 10, heading: 0, altitude: 100, longitude: 10.0, latitude: 50.0, timestamp: Date()),
                RoutePoint(speed: 10, heading: 0, altitude: 100, longitude: 20.0, latitude: 60.0, timestamp: Date())
            ]
            let steps = 1

            // Step 2: Manually calculate the expected result
            let expectedInterpolatedPoints: [CLLocationCoordinate2D] = [
                CLLocationCoordinate2D(latitude: 50.0, longitude: 10.0),
                CLLocationCoordinate2D(latitude: 55.0, longitude: 15.0),  // Interpolated point
                CLLocationCoordinate2D(latitude: 60.0, longitude: 20.0)
            ]

            // Step 3: Invoke the function
            let interpolatedPoints = linearInterpolatePoints(routePoints: points, steps: steps)

            // Step 4: Verify the results
            XCTAssertEqual(interpolatedPoints.count, expectedInterpolatedPoints.count, "The count of interpolated points should match the expected count.")

            for (index, coord) in interpolatedPoints.enumerated() {
                XCTAssertEqual(coord.latitude, expectedInterpolatedPoints[index].latitude, accuracy: 0.00001, "Latitude should match at index \(index)")
                XCTAssertEqual(coord.longitude, expectedInterpolatedPoints[index].longitude, accuracy: 0.00001, "Longitude should match at index \(index)")
            }
        }

}

import CoreLocation

func cubicBezierInterpolatePoints(routePoints: [RoutePoint], steps: Int = 4) -> [CLLocationCoordinate2D] {
#if DEBUG
print("Original points count: \(routePoints.count)")
#endif
    guard routePoints.count > 1 else {
        return []
    }
    
    var interpolatedPoints: [CLLocationCoordinate2D] = []

    for i in 0..<routePoints.count - 1 {
        let p0 = routePoints[i]
        let p1 = routePoints[min(i + 1, routePoints.count - 1)]
        
        // Control points
        let c0 = p0
        let c1 = RoutePoint(
            speed: 0, heading: 0, altitude: 0,
            longitude: (p0.longitude + p1.longitude) / 2.0,
            latitude: (p0.latitude + p1.latitude) / 2.0,
            timestamp: Date()
        )
        
        for j in 0...steps {
            let t = Double(j) / Double(steps)
            let x = cubicBezierValue(t: t, p0: p0.longitude, p1: c0.longitude, p2: c1.longitude, p3: p1.longitude)
            let y = cubicBezierValue(t: t, p0: p0.latitude, p1: c0.latitude, p2: c1.latitude, p3: p1.latitude)
            
#if DEBUG
print("Interpolated point \(j) between (\(p0.latitude), \(p0.longitude)) and (\(p1.latitude), \(p1.longitude)): (\(x), \(y))")
#endif
            interpolatedPoints.append(CLLocationCoordinate2D(latitude: y, longitude: x))
        }
    }
#if DEBUG
print("Interpolated points count: \(interpolatedPoints.count)")
#endif
    return interpolatedPoints
}

func cubicBezierValue(t: Double, p0: Double, p1: Double, p2: Double, p3: Double) -> Double {
    let u = 1.0 - t
    let tt = t * t
    let uu = u * u
    let uuu = uu * u
    let ttt = tt * t
    
    return uuu * p0 + 3 * uu * t * p1 + 3 * u * tt * p2 + ttt * p3
}

func linearInterpolatePoints(routePoints: [RoutePoint], steps: Int = 2) -> [CLLocationCoordinate2D] {
    var interpolatedPoints: [CLLocationCoordinate2D] = []

    #if DEBUG
    print("Original points count: \(routePoints.count)")
    for point in routePoints {
        print("Original point: (\(point.latitude), \(point.longitude))")
    }
    #endif
    
    for i in 0..<routePoints.count - 1 {
        let startPoint = routePoints[i]
        let endPoint = routePoints[i + 1]
        
        interpolatedPoints.append(CLLocationCoordinate2D(latitude: startPoint.latitude, longitude: startPoint.longitude))
        
        let stepFraction = 1.0 / Double(steps + 1)
        
        for j in 1...steps {
            let t = stepFraction * Double(j)
            let lat = (1 - t) * startPoint.latitude + t * endPoint.latitude
            let lon = (1 - t) * startPoint.longitude + t * endPoint.longitude
            
            #if DEBUG
            print("Interpolated point \(j) between (\(startPoint.latitude), \(startPoint.longitude)) and (\(endPoint.latitude), \(endPoint.longitude)): (\(lat), \(lon))")
            #endif
            
            interpolatedPoints.append(CLLocationCoordinate2D(latitude: lat, longitude: lon))
        }
    }
    
    if let lastPoint = routePoints.last {
        interpolatedPoints.append(CLLocationCoordinate2D(latitude: lastPoint.latitude, longitude: lastPoint.longitude))
    }
    
    #if DEBUG
    print("Interpolated points count: \(interpolatedPoints.count)")
    for point in interpolatedPoints {
        print("Interpolated point: (\(point.latitude), \(point.longitude))")
    }
    #endif
    
    return interpolatedPoints
}


func smoothInterpolatePoints(routePoints: [RoutePoint], windowSize: Int = 3) -> [CLLocationCoordinate2D] {
    var smoothedPoints: [CLLocationCoordinate2D] = []

    guard routePoints.count > 1 else {
        return smoothedPoints
    }

    let halfWindow = windowSize / 2

    for i in 0..<routePoints.count {
        var sumLat: Double = 0
        var sumLon: Double = 0
        var count: Int = 0
        
        for j in max(0, i - halfWindow)...min(routePoints.count - 1, i + halfWindow) {
            sumLat += routePoints[j].latitude
            sumLon += routePoints[j].longitude
            count += 1
        }
        
        let avgLat = sumLat / Double(count)
        let avgLon = sumLon / Double(count)
        
        smoothedPoints.append(CLLocationCoordinate2D(latitude: avgLat, longitude: avgLon))
    }

    return smoothedPoints
}


import CoreLocation

func hermiteSplineInterpolatePoints(routePoints: [RoutePoint], steps: Int = 3) -> [CLLocationCoordinate2D] {
    guard routePoints.count > 2 else {
        return routePoints.map { CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude) }
    }
    
    var interpolatedPoints: [CLLocationCoordinate2D] = []
    
    for i in 1..<routePoints.count - 1 {
        let p0 = routePoints[i - 1]
        let p1 = routePoints[i]
        let p2 = routePoints[i + 1]
        
        let t0 = 0.0
        let t1 = 1.0
        let t2 = 2.0
        
        for j in 0...steps {
            let t = t1 + (t2 - t1) * Double(j) / Double(steps)
            
            let h00 = (1 + 2 * (t - t1)) * pow((t - t0) / (t2 - t0), 2)
            let h10 = (t - t0) * pow((t - t0) / (t2 - t0), 2)
            let h01 = (1 - 2 * (t - t1)) * pow((t - t1) / (t2 - t1), 2)
            let h11 = (t - t1) * pow((t - t1) / (t2 - t1), 2)
            
            let lat = h00 * p0.latitude + h10 * (p1.latitude - p0.latitude) + h01 * p1.latitude + h11 * (p2.latitude - p1.latitude)
            let lon = h00 * p0.longitude + h10 * (p1.longitude - p0.longitude) + h01 * p1.longitude + h11 * (p2.longitude - p1.longitude)
            
            interpolatedPoints.append(CLLocationCoordinate2D(latitude: lat, longitude: lon))
        }
    }
    
    // Add the last point
    if let lastPoint = routePoints.last {
        interpolatedPoints.append(CLLocationCoordinate2D(latitude: lastPoint.latitude, longitude: lastPoint.longitude))
    }
    
    return interpolatedPoints
}


struct KalmanFilter {
    var processNoise: Double
    var measurementNoise: Double
    var estimationError: Double
    var value: CLLocationCoordinate2D

    init(processNoise: Double, measurementNoise: Double, estimationError: Double, initialValue: CLLocationCoordinate2D) {
        self.processNoise = processNoise
        self.measurementNoise = measurementNoise
        self.estimationError = estimationError
        self.value = initialValue
    }

    mutating func update(measurement: CLLocationCoordinate2D) {
        let kalmanGainLat = estimationError / (estimationError + measurementNoise)
        let kalmanGainLon = estimationError / (estimationError + measurementNoise)
        
        let newLat = value.latitude + kalmanGainLat * (measurement.latitude - value.latitude)
        let newLon = value.longitude + kalmanGainLon * (measurement.longitude - value.longitude)
        
        value = CLLocationCoordinate2D(latitude: newLat, longitude: newLon)
        
        estimationError = (1 - kalmanGainLat) * estimationError + abs(value.latitude - newLat) * processNoise
        estimationError = (1 - kalmanGainLon) * estimationError + abs(value.longitude - newLon) * processNoise
    }
}

func applyKalmanFilter(routePoints: [RoutePoint], processNoise: Double, measurementNoise: Double) -> [CLLocationCoordinate2D] {
    guard let firstPoint = routePoints.first else { return [] }
    
    var kalmanFilter = KalmanFilter(
        processNoise: processNoise,
        measurementNoise: measurementNoise,
        estimationError: 1.0,
        initialValue: CLLocationCoordinate2D(latitude: firstPoint.latitude, longitude: firstPoint.longitude)
    )
    
    var smoothedPoints: [CLLocationCoordinate2D] = []
    
    for point in routePoints {
        let measurement = CLLocationCoordinate2D(latitude: point.latitude, longitude: point.longitude)
        kalmanFilter.update(measurement: measurement)
        smoothedPoints.append(kalmanFilter.value)
    }
    
    return smoothedPoints
}

import Foundation
import CoreLocation

class CubicSpline {
    private var a: [Double] = []
    private var b: [Double] = []
    private var c: [Double] = []
    private var d: [Double] = []
    private var x: [Double] = []

    init(xs: [Double], ys: [Double]) {
        let n = xs.count - 1
        self.x = xs

        var h: [Double] = []
        var alpha: [Double] = []
        for i in 0..<n {
            h.append(xs[i + 1] - xs[i])
            alpha.append(3.0 * (ys[i + 1] - ys[i]) / h[i])
        }

        var l: [Double] = [1.0]
        var mu: [Double] = [0.0]
        var z: [Double] = [0.0]

        for i in 1..<n {
            let li = 2.0 * (xs[i + 1] - xs[i - 1]) - h[i - 1] * mu[i - 1]
            l.append(li)
            let mui = h[i] / li
            mu.append(mui)
            let zi = (alpha[i] - h[i - 1] * z[i - 1]) / li
            z.append(zi)
        }

        l.append(1.0)
        z.append(0.0)
        c = Array(repeating: 0.0, count: xs.count)
        b = Array(repeating: 0.0, count: xs.count)
        d = Array(repeating: 0.0, count: xs.count)
        c[xs.count - 1] = 0.0

        for j in stride(from: n - 1, through: 0, by: -1) {
            c[j] = z[j] - mu[j] * c[j + 1]
            b[j] = (ys[j + 1] - ys[j]) / h[j] - h[j] * (c[j + 1] + 2.0 * c[j]) / 3.0
            d[j] = (c[j + 1] - c[j]) / (3.0 * h[j])
            a.append(ys[j])
        }

        a.reverse()
    }

    func interpolate(x: Double) -> Double {
        let n = self.x.count - 1

        var i = n - 1
        for j in 0..<n {
            if x >= self.x[j] && x <= self.x[j + 1] {
                i = j
                break
            }
        }

        let dx = x - self.x[i]
        return a[i] + b[i] * dx + c[i] * dx + d[i] * dx * dx * dx
    }
}

extension CLLocationCoordinate2D {
    static func smoothPath(points: [CLLocationCoordinate2D], granularity: Int = 100) -> [CLLocationCoordinate2D] {
        var smoothedPoints: [CLLocationCoordinate2D] = []

        let latitudes = points.map { $0.latitude }
        let longitudes = points.map { $0.longitude }

        let latitudeSpline = CubicSpline(xs: Array(0..<latitudes.count).map { Double($0) }, ys: latitudes)
        let longitudeSpline = CubicSpline(xs: Array(0..<longitudes.count).map { Double($0) }, ys: longitudes)

        for i in 0..<latitudes.count - 1 {
            let step = 1.0 / Double(granularity)
            for t in stride(from: 0.0, to: 1.0, by: step) {
                let lat = latitudeSpline.interpolate(x: Double(i) + t)
                let lon = longitudeSpline.interpolate(x: Double(i) + t)
                smoothedPoints.append(CLLocationCoordinate2D(latitude: lat, longitude: lon))
            }
        }

        smoothedPoints.append(points.last!)
        return smoothedPoints
    }
}

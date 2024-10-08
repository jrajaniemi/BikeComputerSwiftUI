

import HealthKit
import Combine

class HealthKitManager: ObservableObject {
    let healthStore = HKHealthStore()
    
    @Published var heartRate: Double?
    private var timer: Timer?

    func requestAuthorization(completion: @escaping (Bool, Error?) -> Void) {
        let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!

        let typesToRead: Set<HKObjectType> = [heartRateType]

        healthStore.requestAuthorization(toShare: nil, read: typesToRead) { (success, error) in
            completion(success, error)
        }
    }

    func startHeartRateUpdates() {
        // Luo ajastin, joka käynnistyy 5 sekunnin välein ja hakee sykkeen
        timer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { [weak self] _ in
            self?.fetchHeartRateData()
        }
    }

    func stopHeartRateUpdates() {
        timer?.invalidate() // Pysäytä ajastin
        timer = nil
    }

    func fetchHeartRateData() {
        let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        
        let query = HKSampleQuery(sampleType: heartRateType, predicate: nil, limit: 1, sortDescriptors: [sortDescriptor]) { (query, results, error) in
            guard let results = results as? [HKQuantitySample], error == nil else {
                return
            }
            
            DispatchQueue.main.async {
                self.heartRate = results.first?.quantity.doubleValue(for: HKUnit.count().unitDivided(by: HKUnit.minute()))
            }
        }
        
        healthStore.execute(query)
    }
}

import Foundation
import Combine

struct CodeEntry: Codable, Identifiable {
    var id = UUID()
    let code: String
    let date: Date
    let lockDurationHours: Double
}

class CodeManager: ObservableObject {
    @Published var history: [CodeEntry] = []
    
    private let historyKey = "BlockApps_CodeHistory"
    
    init() {
        loadData()
    }
    
    func loadData() {
        if let data = UserDefaults.standard.data(forKey: historyKey),
           let decoded = try? JSONDecoder().decode([CodeEntry].self, from: data) {
            self.history = decoded
        }
    }
    
    func saveData() {
        if let encoded = try? JSONEncoder().encode(history) {
            UserDefaults.standard.set(encoded, forKey: historyKey)
        }
    }
    
    func generateNewCodeString() -> String {
        let newCodeInt = Int.random(in: 0...9999)
        return String(format: "%04d", newCodeInt)
    }
    
    func saveGeneratedCode(_ code: String, lockDurationHours: Double) {
        let newEntry = CodeEntry(code: code, date: Date(), lockDurationHours: lockDurationHours)
        history.append(newEntry)
        saveData()
    }
    
    var currentCode: String {
        return history.last?.code ?? ""
    }
    
    var currentGeneratedDate: Date? {
        return history.last?.date
    }
    
    var currentRevealDate: Date? {
        guard let last = history.last else { return nil }
        return last.date.addingTimeInterval(last.lockDurationHours * 3600)
    }
    
    var shouldShowCode: Bool {
        guard let revealDate = currentRevealDate else { return false }
        return Date() >= revealDate
    }
    
    var visibleHistory: [CodeEntry] {
        if history.isEmpty { return [] }
        
        let now = Date()
        let visible = history.filter { entry in
            let requiredSeconds = entry.lockDurationHours * 3600
            return now.timeIntervalSince(entry.date) >= requiredSeconds
        }
        
        return visible.reversed() // Most recent first
    }
}

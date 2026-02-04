import Foundation
import Combine

class OverlayQueueManager: ObservableObject {
    @Published var queue: [OverlayKey] = []
    
    private let maxItems = 2
    private let storageKey = "overlay_queue"
    
    init() {
        load()
    }
    
    func add(_ key: String) {
        let item = OverlayKey(key: key)
        queue.insert(item, at: 0)
        
        if queue.count > maxItems {
            queue.removeLast()
        }
        
        save()
    }
    
    func removeItem(withId id: UUID) {
        queue.removeAll { $0.id == id } // <-- FIX: remove by UUID
        save()
    }
    
    private func save() {
        if let data = try? JSONEncoder().encode(queue) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
    
    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([OverlayKey].self, from: data) else {
            return
        }
        queue = decoded
    }
}

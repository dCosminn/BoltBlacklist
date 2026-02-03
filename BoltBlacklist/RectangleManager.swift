import SwiftUI
import Combine

class RectangleManager: ObservableObject {
    @Published var rect: CGRect = .zero
    
    private let storageKey = "rect_position"
    private var containerSize: CGSize = .zero
    
    func initialize(in size: CGSize) {
        containerSize = size
        
        if rect == .zero {
            if let data = UserDefaults.standard.data(forKey: storageKey),
               let position = try? JSONDecoder().decode(RectPosition.self, from: data) {
                rect = position.toRect(in: size)
            } else {
                rect = RectPosition.default.toRect(in: size)
            }
        }
    }
    
    func save() {
        guard containerSize.width > 0 && containerSize.height > 0 else { return }
        
        let position = RectPosition.from(rect, in: containerSize)
        if let data = try? JSONEncoder().encode(position) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
    
    func updateRect(_ newRect: CGRect, keepInBounds size: CGSize) {
        var bounded = newRect
        
        // Keep in bounds
        bounded.origin.x = max(0, min(bounded.origin.x, size.width - bounded.width))
        bounded.origin.y = max(0, min(bounded.origin.y, size.height - bounded.height))
        
        // Enforce minimum size
        bounded.size.width = max(100, bounded.size.width)
        bounded.size.height = max(100, bounded.size.height)
        
        rect = bounded
    }
}

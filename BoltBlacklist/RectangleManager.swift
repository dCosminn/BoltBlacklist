import SwiftUI
import Combine

final class RectangleManager: ObservableObject {
    @Published var rect: CGRect = .zero

    private let storageKey: String
    private var containerSize: CGSize = .zero
    private var hasInitialized = false
    
    init(storageKey: String = "rect_position") {
        self.storageKey = storageKey
    }

    // MARK: - Initialization (run ONCE)
    func initialize(in size: CGSize) {
        // Always keep latest container size
        containerSize = size

        // Do NOT reinitialize if already done
        guard !hasInitialized else { return }
        hasInitialized = true

        // Try restoring saved rect
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let position = try? JSONDecoder().decode(RectPosition.self, from: data) {
            rect = position.toRect(in: size)
        } else {
            // Default rect (centered & visible)
            rect = RectPosition.default.toRect(in: size)
        }
    }

    // MARK: - Save
    func save() {
        guard containerSize.width > 0, containerSize.height > 0 else { return }

        let position = RectPosition.from(rect, in: containerSize)
        if let data = try? JSONEncoder().encode(position) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    // MARK: - Safe Update Helper
    func updateRect(_ newRect: CGRect) {
        guard containerSize != .zero else {
            rect = newRect
            return
        }

        var bounded = newRect

        // Keep inside bounds
        bounded.origin.x = max(0, min(bounded.origin.x, containerSize.width - bounded.width))
        bounded.origin.y = max(0, min(bounded.origin.y, containerSize.height - bounded.height))

        // Minimum size
        bounded.size.width = max(100, bounded.size.width)
        bounded.size.height = max(100, bounded.size.height)

        rect = bounded
    }
}

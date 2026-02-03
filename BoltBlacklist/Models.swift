import Foundation
import CoreGraphics

struct OverlayKey: Identifiable, Codable, Equatable {
    let id: UUID
    let key: String
    let timestamp: String
    
    init(key: String) {
        self.id = UUID()
        self.key = key.uppercased()
        
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy HH:mm:ss"
        self.timestamp = formatter.string(from: Date())
    }
    
    init(id: UUID, key: String, timestamp: String) {
        self.id = id
        self.key = key
        self.timestamp = timestamp
    }
}

struct RectPosition: Codable {
    var left: CGFloat
    var top: CGFloat
    var right: CGFloat
    var bottom: CGFloat
    
    func toRect(in size: CGSize) -> CGRect {
        CGRect(
            x: left * size.width,
            y: top * size.height,
            width: (right - left) * size.width,
            height: (bottom - top) * size.height
        )
    }
    
    static func from(_ rect: CGRect, in size: CGSize) -> RectPosition {
        RectPosition(
            left: rect.minX / size.width,
            top: rect.minY / size.height,
            right: rect.maxX / size.width,
            bottom: rect.maxY / size.height
        )
    }
    
    static let `default` = RectPosition(left: 0.25, top: 0.35, right: 0.75, bottom: 0.65)
}

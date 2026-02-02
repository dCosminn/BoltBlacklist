import SwiftUI
import UIKit

struct OverlayViewRepresentable: UIViewRepresentable {
    @Binding var ocrText: String

    func makeUIView(context: Context) -> OverlayView {
        OverlayView()
    }

    func updateUIView(_ uiView: OverlayView, context: Context) {
        uiView.ocrText = ocrText
    }
}

class OverlayView: UIView {

    var rect = CGRect(x: 100, y: 200, width: 300, height: 150)
    var lastPoint = CGPoint.zero
    var dragging = false
    var ocrText = "" { didSet { setNeedsDisplay() } }

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        backgroundColor = .clear
    }

    override func draw(_ r: CGRect) {
        guard let ctx = UIGraphicsGetCurrentContext() else { return }

        ctx.setStrokeColor(UIColor.red.cgColor)
        ctx.setLineWidth(4)
        ctx.stroke(rect)

        if !ocrText.isEmpty {
            let attrs: [NSAttributedString.Key: Any] = [
                .foregroundColor: UIColor.green,
                .font: UIFont.boldSystemFont(ofSize: 22)
            ]
            ocrText.draw(at: CGPoint(x: rect.minX,
                                     y: rect.maxY + 6),
                         withAttributes: attrs)
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let p = touches.first?.location(in: self) else { return }
        if rect.contains(p) {
            dragging = true
            lastPoint = p
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard dragging,
              let p = touches.first?.location(in: self) else { return }

        let dx = p.x - lastPoint.x
        let dy = p.y - lastPoint.y
        rect = rect.offsetBy(dx: dx, dy: dy)
        lastPoint = p
        setNeedsDisplay()
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        dragging = false
    }
}

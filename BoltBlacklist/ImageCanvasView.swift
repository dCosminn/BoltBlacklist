import SwiftUI
import UIKit

// MARK: - Image Canvas with Resizable Rectangle
struct ImageCanvasView: View {
    @Binding var image: UIImage?
    @ObservedObject var boltRectangleManager: RectangleManager
    @ObservedObject var uberRectangleManager: RectangleManager
    @Binding var imageDisplayRect: CGRect
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Display the image
                if let img = image {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFit()
                        .background(
                            GeometryReader { geo in
                                Color.clear
                                    // Use named coordinate space to get REAL screen position
                                    .onAppear {
                                        imageDisplayRect = geo.frame(in: .named("Canvas"))
                                    }
                                    .onChange(of: geo.frame(in: .named("Canvas"))) { _, newFrame in
                                        imageDisplayRect = newFrame
                                    }
                            }
                        )
                } else {
                    Text("No Picture")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                // Bolt Rectangle (GREEN)
                ResizableRectangle(
                    rect: $boltRectangleManager.rect,
                    containerSize: image != nil ? imageDisplayRect.size : geometry.size,
                    color: .green,
                    onDragEnd: { boltRectangleManager.save() }
                )

                // Uber Rectangle (RED)
                ResizableRectangle(
                    rect: $uberRectangleManager.rect,
                    containerSize: image != nil ? imageDisplayRect.size : geometry.size,
                    color: .red,
                    onDragEnd: { uberRectangleManager.save() }
                )
            }
            //Define the coordinate space on the container
            .coordinateSpace(name: "Canvas")
            .onAppear {
                boltRectangleManager.initialize(in: geometry.size)
                uberRectangleManager.initialize(in: geometry.size)
            }
        }
    }
}

// MARK: - Resizable Rectangle
struct ResizableRectangle: View {
    @Binding var rect: CGRect
    let containerSize: CGSize
    let color: Color  // ← ADD THIS
    let onDragEnd: () -> Void
    
    @State private var startRect: CGRect = .zero
    
    var body: some View {
        ZStack {
            // Invisible draggable area (fills entire rectangle)
            Rectangle()
                .fill(Color.white.opacity(0.001))  //Nearly invisible but draggable!
                .frame(width: rect.width, height: rect.height)
                .position(x: rect.midX, y: rect.midY)
                .gesture(moveGesture)
            

            // Visible border
            Rectangle()
                .stroke(color, lineWidth: 3)
                .frame(width: rect.width, height: rect.height)
                .position(x: rect.midX, y: rect.midY)
                .allowsHitTesting(false)  //Don't block gestures!
            
            // Corner handles
            ForEach(Corner.allCases, id: \.self) { corner in
                CornerHandle(corner: corner, rect: $rect, containerSize: containerSize, color: color, onEnd: onDragEnd)
            }
        }
    }
    
    
    // Move the rectangle
    private var moveGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                if startRect == .zero {
                    startRect = rect
                }
                
                var newRect = startRect
                newRect.origin.x += value.translation.width
                newRect.origin.y += value.translation.height
                
                // Keep in bounds
                newRect.origin.x = max(0, min(newRect.origin.x, containerSize.width - newRect.width))
                newRect.origin.y = max(0, min(newRect.origin.y, containerSize.height - newRect.height))
                
                rect = newRect
            }
            .onEnded { _ in
                startRect = .zero
                onDragEnd()
            }
    }
}

// MARK: - Corner Handles
enum Corner: CaseIterable {
    case topLeft, topRight, bottomLeft, bottomRight
}

struct CornerHandle: View {
    let corner: Corner
    @Binding var rect: CGRect
    let containerSize: CGSize
    let color: Color  // ← ADD THIS
    let onEnd: () -> Void
    
    @State private var startRect: CGRect = .zero
    
    var body: some View {
        ZStack {
            // Larger invisible tap target (44x44 - Apple's recommended minimum)
            Circle()
                .fill(Color.white.opacity(0.001))
                .frame(width: 44, height: 44)
                .position(position)
                .gesture(resizeGesture)
            
            // Visible handle
            Circle()
                .fill(color)
                .frame(width: 20, height: 20)
                .position(position)
                .allowsHitTesting(false)
        }
    }
    
    private var position: CGPoint {
        switch corner {
        case .topLeft: return CGPoint(x: rect.minX, y: rect.minY)
        case .topRight: return CGPoint(x: rect.maxX, y: rect.minY)
        case .bottomLeft: return CGPoint(x: rect.minX, y: rect.maxY)
        case .bottomRight: return CGPoint(x: rect.maxX, y: rect.maxY)
        }
    }
    
    private var resizeGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                if startRect == .zero {
                    startRect = rect
                }
                
                let minSize: CGFloat = 30
                
                // Calculate the new corner position
                var newRect = startRect
                
                switch corner {
                case .topLeft:
                    // Moving top-left corner
                    let newX = startRect.minX + value.translation.width
                    let newY = startRect.minY + value.translation.height
                    
                    // Don't allow going past opposite corner (minus minimum size)
                    let maxX = startRect.maxX - minSize
                    let maxY = startRect.maxY - minSize
                    
                    let clampedX = min(newX, maxX)
                    let clampedY = min(newY, maxY)
                    
                    newRect = CGRect(
                        x: clampedX,
                        y: clampedY,
                        width: startRect.maxX - clampedX,
                        height: startRect.maxY - clampedY
                    )
                    
                case .topRight:
                    // Moving top-right corner
                    let newX = startRect.maxX + value.translation.width
                    let newY = startRect.minY + value.translation.height
                    
                    // Don't allow going past opposite corner (minus minimum size)
                    let minX = startRect.minX + minSize
                    let maxY = startRect.maxY - minSize
                    
                    let clampedX = max(newX, minX)
                    let clampedY = min(newY, maxY)
                    
                    newRect = CGRect(
                        x: startRect.minX,
                        y: clampedY,
                        width: clampedX - startRect.minX,
                        height: startRect.maxY - clampedY
                    )
                    
                case .bottomLeft:
                    // Moving bottom-left corner
                    let newX = startRect.minX + value.translation.width
                    let newY = startRect.maxY + value.translation.height
                    
                    // Don't allow going past opposite corner (minus minimum size)
                    let maxX = startRect.maxX - minSize
                    let minY = startRect.minY + minSize
                    
                    let clampedX = min(newX, maxX)
                    let clampedY = max(newY, minY)
                    
                    newRect = CGRect(
                        x: clampedX,
                        y: startRect.minY,
                        width: startRect.maxX - clampedX,
                        height: clampedY - startRect.minY
                    )
                    
                case .bottomRight:
                    // Moving bottom-right corner
                    let newX = startRect.maxX + value.translation.width
                    let newY = startRect.maxY + value.translation.height
                    
                    // Don't allow going past opposite corner (minus minimum size)
                    let minX = startRect.minX + minSize
                    let minY = startRect.minY + minSize
                    
                    let clampedX = max(newX, minX)
                    let clampedY = max(newY, minY)
                    
                    newRect = CGRect(
                        x: startRect.minX,
                        y: startRect.minY,
                        width: clampedX - startRect.minX,
                        height: clampedY - startRect.minY
                    )
                }
                
                // Keep in bounds
                if newRect.minX >= 0 && newRect.maxX <= containerSize.width &&
                   newRect.minY >= 0 && newRect.maxY <= containerSize.height {
                    rect = newRect
                }
            }
            .onEnded { _ in
                startRect = .zero
                onEnd()
            }
    }
}

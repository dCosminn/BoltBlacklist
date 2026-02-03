import SwiftUI

struct ImageCanvasView: View {
    @Binding var image: UIImage?
    @ObservedObject var rectangleManager: RectangleManager
    @Binding var imageDisplayRect: CGRect
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Image if available
                if let image = image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .background(
                            GeometryReader { imageGeo in
                                Color.clear.onAppear {
                                    imageDisplayRect = imageGeo.frame(in: .local)
                                    
                                    // Keep rectangle inside the image bounds
                                    rectangleManager.rect = rectangleManager.rect
                                        .intersection(imageGeo.frame(in: .local))
                                }
                                .onChange(of: imageGeo.size) {
                                    imageDisplayRect = imageGeo.frame(in: .local)
                                }
                            }
                        )
                } else {
                    // Placeholder when no image
                    Text("No Image")
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                
                // Rectangle always visible
                ResizableRectangle(
                    rect: $rectangleManager.rect,
                    containerSize: image != nil ? imageDisplayRect.size : geometry.size,
                    onDragEnd: { rectangleManager.save() }
                )
            }
            .onAppear {
                // Initialize rectangle to screen if not already
                rectangleManager.initialize(in: geometry.size)
            }
            .onChange(of: geometry.size) {
                rectangleManager.initialize(in: geometry.size)
            }
        }
    }
}

// MARK: - Resizable Rectangle
struct ResizableRectangle: View {
    @Binding var rect: CGRect
    let containerSize: CGSize
    let onDragEnd: () -> Void
    
    @State private var dragOffset: CGSize = .zero
    
    var body: some View {
        ZStack {
            // Rectangle outline
            Rectangle()
                .stroke(Color.red, lineWidth: 2)
                .frame(width: rect.width, height: rect.height)
                .position(x: rect.midX + dragOffset.width, y: rect.midY + dragOffset.height)
                .gesture(moveGesture)
            
            // Corner handles
            ForEach(Corner.allCases, id: \.self) { corner in
                CornerHandle(corner: corner, rect: $rect, containerSize: containerSize, onEnd: onDragEnd)
            }
        }
    }
    
    private var moveGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                dragOffset = value.translation
            }
            .onEnded { value in
                var newRect = rect
                newRect.origin.x += value.translation.width
                newRect.origin.y += value.translation.height
                
                // Keep in bounds
                newRect.origin.x = max(0, min(newRect.origin.x, containerSize.width - newRect.width))
                newRect.origin.y = max(0, min(newRect.origin.y, containerSize.height - newRect.height))
                
                rect = newRect
                dragOffset = .zero
                onDragEnd()
            }
    }
}

// MARK: - Corner Handle
enum Corner: CaseIterable {
    case topLeft, topRight, bottomLeft, bottomRight
}

struct CornerHandle: View {
    let corner: Corner
    @Binding var rect: CGRect
    let containerSize: CGSize
    let onEnd: () -> Void
    
    var body: some View {
        Circle()
            .fill(Color.red)
            .frame(width: 15, height: 15)
            .position(position)
            .gesture(resizeGesture)
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
                var newRect = rect
                
                switch corner {
                case .topLeft:
                    newRect.origin.x += value.translation.width
                    newRect.size.width -= value.translation.width
                    newRect.origin.y += value.translation.height
                    newRect.size.height -= value.translation.height
                case .topRight:
                    newRect.size.width += value.translation.width
                    newRect.origin.y += value.translation.height
                    newRect.size.height -= value.translation.height
                case .bottomLeft:
                    newRect.origin.x += value.translation.width
                    newRect.size.width -= value.translation.width
                    newRect.size.height += value.translation.height
                case .bottomRight:
                    newRect.size.width += value.translation.width
                    newRect.size.height += value.translation.height
                }
                
                // Enforce constraints
                if newRect.width >= 100 && newRect.height >= 100 &&
                   newRect.minX >= 0 && newRect.maxX <= containerSize.width &&
                   newRect.minY >= 0 && newRect.maxY <= containerSize.height {
                    rect = newRect
                }
            }
            .onEnded { _ in
                onEnd()
            }
    }
}


import SwiftUI

struct OverlayQueueView: View {
    let queue: [OverlayKey]
    let onTap: (UUID) -> Void
    let onRemove: (Int) -> Void
    
    var body: some View {
        VStack {
            HStack {
                Spacer()
                VStack(alignment: .trailing, spacing: 10) {
                    ForEach(Array(queue.enumerated()), id: \.element.id) { index, item in
                        OverlayKeyCard(
                            item: item,
                            onTap: { onTap(item.id) },
                            onSwipe: { onRemove(index) }
                        )
                    }
                }
                .padding(.trailing, 10)
            }
            .padding(.top, 50)
            Spacer()
        }
    }
}

struct OverlayKeyCard: View {
    let item: OverlayKey
    let onTap: () -> Void
    let onSwipe: () -> Void
    
    @State private var offset: CGFloat = 0
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 2) {
            Text(item.timestamp)
                .font(.system(size: 18))
                .foregroundColor(.white)
            Text(item.key)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
        }
        .padding(10)
        .background(Color(white: 0.19))
        .cornerRadius(10)
        .offset(x: offset)
        .gesture(swipeGesture)
    }
    
    private var swipeGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                offset = value.translation.width
            }
            .onEnded { value in
                if abs(value.translation.width) > 80 {
                    onSwipe()
                } else if abs(value.translation.width) < 10 {
                    onTap()
                }
                withAnimation {
                    offset = 0
                }
            }
    }
}

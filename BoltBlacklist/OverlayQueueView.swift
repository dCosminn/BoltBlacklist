import SwiftUI

struct OverlayQueueView: View {
    @ObservedObject var queueManager: OverlayQueueManager
    let onTap: (UUID) -> Void
    
    var body: some View {
        VStack {
            HStack {
                Spacer()
                VStack(alignment: .trailing, spacing: 10) {
                    ForEach(queueManager.queue) { item in
                        OverlayKeyCard(
                            item: item,
                            onTap: { onTap(item.id) },
                            onSwipe: { queueManager.removeItem(withId: item.id) }
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
    @State private var isDragging = false
    
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
        .contentShape(Rectangle())  //Makes ENTIRE card tappable (including padding!)
        .onTapGesture {  //Separate tap gesture - much more reliable!
            if !isDragging {
                onTap()
            }
        }
        .gesture(swipeGesture)  //Only for swipes
    }
    
    private var swipeGesture: some Gesture {
        DragGesture(minimumDistance: 10)  //Needs 10px movement to start
            .onChanged { value in
                isDragging = true
                offset = value.translation.width
            }
            .onEnded { value in
                let horizontalMovement = abs(value.translation.width)
                let verticalMovement = abs(value.translation.height)
                
                // Only swipe if mostly horizontal and moved enough
                if horizontalMovement > 80 && horizontalMovement > verticalMovement {
                    onSwipe()
                }
                
                // Bounce back with spring animation
                withAnimation(.spring(response: 0.3)) {
                    offset = 0
                }
                
                // Delay resetting isDragging so tap doesn't trigger
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isDragging = false
                }
            }
    }
}

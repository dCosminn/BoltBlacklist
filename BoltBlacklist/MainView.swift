import SwiftUI
import PhotosUI

struct MainView: View {
    @EnvironmentObject var coordinator: AppCoordinator
    @StateObject private var viewModel = MainViewModel()
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Image area
                ImageCanvasView(
                    image: $viewModel.currentImage,
                    rectangleManager: viewModel.rectangleManager,
                    imageDisplayRect: $viewModel.imageDisplayRect
                )
                
                // Buttons
                ButtonBar(
                    onPickImage: { viewModel.showPhotoPicker = true },
                    onChangeFile: {
                        viewModel.newFileName = FileService.shared.getFileName()
                        viewModel.showFileNameDialog = true
                    },
                    onRunOCR: { viewModel.runOCR() }
                )
                .padding(.bottom, 24)
            }
            
            // Overlay queue
            OverlayQueueView(
                queue: viewModel.overlayQueue.queue,
                onTap: { viewModel.handleOverlayTap(id: $0) },
                onRemove: { index in viewModel.overlayQueue.remove(at: index) }
            )
        }
        .sheet(isPresented: $viewModel.showPhotoPicker) {
            ImagePicker(image: $viewModel.currentImage)
        }
        .alert(viewModel.alertTitle, isPresented: $viewModel.showAlert) {
            Button("OK") {}
        } message: {
            Text(viewModel.alertMessage)
        }
        .alert("File Name", isPresented: $viewModel.showFileNameDialog) {
            TextField("File name", text: $viewModel.newFileName)
            Button("OK") { viewModel.saveFileName() }
            Button("Cancel", role: .cancel) {}
        }
        .alert("Add Text", isPresented: $viewModel.showAddTextDialog) {
            TextField("Enter text", text: $viewModel.additionalText)
            Button("OK") { viewModel.saveKeyWithText() }
            Button("Cancel", role: .cancel) {}
        }
        .onChange(of: coordinator.sharedImage) { _, image in
            if let image = image {
                viewModel.currentImage = image
                if coordinator.shouldRunOCR {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        viewModel.runOCR()
                        coordinator.shouldRunOCR = false
                    }
                }
            }
        }
    }
}

// MARK: - Button Bar
struct ButtonBar: View {
    let onPickImage: () -> Void
    let onChangeFile: () -> Void
    let onRunOCR: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            ActionButton(title: "File Name", color: .purple, action: onChangeFile)
            ActionButton(title: "Add Picture", color: .purple, action: onPickImage)
            ActionButton(title: "Run OCR", color: .teal, action: onRunOCR)
        }
    }
}

struct ActionButton: View {
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(color)
                .cornerRadius(8)
        }
    }
}

extension Color {
    static let purple = Color(red: 0.38, green: 0.0, blue: 0.93)
    static let teal = Color(red: 0.01, green: 0.85, blue: 0.77)
}

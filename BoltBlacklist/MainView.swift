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
                    boltRectangleManager: viewModel.boltRectangleManager,
                    uberRectangleManager: viewModel.uberRectangleManager,
                    imageDisplayRect: $viewModel.imageDisplayRect
                )

                // Buttons
                ButtonBar(
                    onPickImage: { viewModel.showPhotoPicker = true },
                    onOpenFile: { viewModel.openFile() },
                    onRunBoltOCR: { viewModel.runBoltOCR() },
                    onRunUberOCR: { viewModel.runUberOCR() }
                )
                .padding(.bottom, 24)
            }

            // Overlay queue
            OverlayQueueView(
                queueManager: viewModel.overlayQueue,
                onTap: { viewModel.handleOverlayTap(id: $0) }
            )
        }
        .sheet(isPresented: $viewModel.showPhotoPicker) {
            ImagePicker(image: $viewModel.currentImage)
        }
        .sheet(isPresented: $viewModel.showShareSheet) {
            ShareSheet(fileURL: FileService.shared.getFileURL())
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
        } message: {
            Text("Enter name for your OCR results file")
        }
        .alert("Add Text", isPresented: $viewModel.showAddTextDialog) {
            TextField("Enter text", text: $viewModel.additionalText)
            Button("OK") { viewModel.saveKeyWithText() }
            Button("Cancel", role: .cancel) {}
        }
        .onChange(of: coordinator.sharedImage) { _, image in
            if let image = image {
                viewModel.currentImage = image
                if coordinator.shouldRunBoltOCR {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        viewModel.runBoltOCR()  // Auto-run Bolt OCR
                        coordinator.shouldRunBoltOCR = false
                    }
                }
            }
        }
    }
}

//
// MARK: - Button Bar
//

struct ButtonBar: View {
    let onPickImage: () -> Void
    let onOpenFile: () -> Void
    let onRunBoltOCR: () -> Void
    let onRunUberOCR: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            // Top row - File and Picture buttons
            HStack(spacing: 16) {
                ActionButton(title: "Open File", color: .purple, action: onOpenFile)
                ActionButton(title: "Add Picture", color: .purple, action: onPickImage)
            }
            
            // Bottom row - OCR buttons
            HStack(spacing: 16) {
                ActionButton(title: "OCR Bolt 🟢", color: .green, action: onRunBoltOCR)
                ActionButton(title: "OCR Uber 🔴", color: .red, action: onRunUberOCR)
            }
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

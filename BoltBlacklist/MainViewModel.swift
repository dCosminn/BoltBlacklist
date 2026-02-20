import SwiftUI
import Combine

class MainViewModel: ObservableObject {
    @Published var currentImage: UIImage?
    @Published var showPhotoPicker = false
    @Published var alertTitle = ""
    @Published var alertMessage = ""
    @Published var showAlert = false
    @Published var showFileNameDialog = false
    @Published var showAddTextDialog = false
    @Published var showShareSheet = false
    @Published var newFileName = ""
    @Published var additionalText = ""
    @Published var imageDisplayRect: CGRect = .zero
    
    // TWO rectangle managers - one for Bolt (green), one for Uber (red)
    let boltRectangleManager = RectangleManager(storageKey: "bolt_rect_position")
    let uberRectangleManager = RectangleManager(storageKey: "uber_rect_position")
    let overlayQueue = OverlayQueueManager()
    
    private var selectedKeyId: UUID?
    private let fileService = FileService.shared
    private let ocrService = OCRService.shared
    
    init() {
        newFileName = fileService.getFileName()
        loadLatestScreenshot()  // Auto-load on open
    }
    
    // Load newest screenshot from Photos
    func loadLatestScreenshot() {
        PhotoService.shared.getLatestScreenshot { [weak self] image in
            DispatchQueue.main.async {
                self?.currentImage = image
            }
        }
    }
    
    // Run OCR for Bolt (green rectangle)
    func runBoltOCR() {
        runOCR(using: boltRectangleManager, service: "Bolt")
    }
    
    // Run OCR for Uber (red rectangle)
    func runUberOCR() {
        runOCR(using: uberRectangleManager, service: "Uber")
    }
    
    // Generic OCR function (private)
    private func runOCR(using rectangleManager: RectangleManager, service: String) {
        guard let image = currentImage else {
            showMessage("No image loaded")
            return
        }
        
        guard imageDisplayRect != .zero else {
            showMessage("Image not ready")
            return
        }
        
        ocrService.recognizeText(
            in: image,
            rect: rectangleManager.rect,
            imageDisplayRect: imageDisplayRect
        ) { [weak self] result in
            DispatchQueue.main.async {
                self?.handleOCRResult(result, service: service)
            }
        }
    }
    
    private func handleOCRResult(_ result: Result<String, Error>, service: String) {
        switch result {
        case .success(let text):
            guard !text.isEmpty else {
                showMessage("No text detected")
                return
            }
            
            let key = ocrService.extractKey(from: text)
            guard !key.isEmpty else { return }
            
            if let duplicate = fileService.findDuplicate(for: key) {
                showDuplicateAlert(duplicate)
            } else {
                overlayQueue.add(key)
            }
            
        case .failure(let error):
            showMessage("OCR failed: \(error.localizedDescription)")
        }
    }
    
    func saveFileName() {
        let name = newFileName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        fileService.setFileName(name)
        showMessage("File name updated")
    }
    
    func openFile() {
        showShareSheet = true
    }
    
    func handleOverlayTap(id: UUID) {
        selectedKeyId = id
        additionalText = ""
        showAddTextDialog = true
    }
    
    func saveKeyWithText() {
        guard let id = selectedKeyId,
              let item = overlayQueue.queue.first(where: { $0.id == id }) else {
            return
        }
        
        let text = additionalText.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }
        
        fileService.appendLine("\(item.key) - \(text)")
        overlayQueue.removeItem(withId: id)
        showMessage("Added: \(item.key) - \(text)")
    }
    
    private func showDuplicateAlert(_ line: String) {
        alertTitle = "Duplicate Detected!"
        alertMessage = "This key already exists:\n\n\(line)"
        showAlert = true
    }
    
    private func showMessage(_ message: String) {
        alertTitle = "Notice"
        alertMessage = message
        showAlert = true
    }
}

import UIKit
import Vision

class OCRService {
    static let shared = OCRService()
    
    func recognizeText(
        in image: UIImage,
        rect: CGRect,
        imageDisplayRect: CGRect,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        guard let cgImage = image.cgImage else {
            completion(.failure(OCRError.invalidImage))
            return
        }
        
        // Simple coordinate conversion - displayRect now has correct x/y offsets!
        let cropRect = calculateCropRect(
            overlayRect: rect,
            imageSize: image.size,
            imageScale: image.scale,
            displayRect: imageDisplayRect
        )
        
        guard let croppedCGImage = cgImage.cropping(to: cropRect) else {
            completion(.failure(OCRError.croppingFailed))
            return
        }
        
        let request = VNRecognizeTextRequest { request, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                completion(.failure(OCRError.noResults))
                return
            }
            
            let text = observations
                .compactMap { $0.topCandidates(1).first?.string }
                .joined(separator: "\n")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            
            completion(.success(text))
        }
        
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        
        let handler = VNImageRequestHandler(cgImage: croppedCGImage, options: [:])
        DispatchQueue.global(qos: .userInitiated).async {
            try? handler.perform([request])
        }
    }
        
    private func calculateCropRect(
        overlayRect: CGRect,
        imageSize: CGSize,
        imageScale: CGFloat,
        displayRect: CGRect  // Now contains the real X/Y offsets (e.g., x:35 for letterbox)
    ) -> CGRect {
        
        // 1. Calculate the scale (Image Pixels vs Screen Points)
        let pixelWidth = imageSize.width * imageScale
        let pixelHeight = imageSize.height * imageScale
        
        // Scale factor (width ratio - height ratio is identical due to aspect fit)
        let scale = pixelWidth / displayRect.width
        
        // 2. Subtract the Display Offset (Black Bars) to find X/Y relative to the image
        // overlayRect is in Screen Coordinates
        // displayRect is the Image's Screen Coordinates (includes offset!)
        let relativeX = overlayRect.minX - displayRect.minX
        let relativeY = overlayRect.minY - displayRect.minY
        
        // 3. Convert to Image Pixels
        let cropX = relativeX * scale
        let cropY = relativeY * scale
        let cropWidth = overlayRect.width * scale
        let cropHeight = overlayRect.height * scale
        
        // 4. Create safe rect preventing out-of-bounds crashes
        return CGRect(
            x: max(0, min(cropX, pixelWidth - 1)),
            y: max(0, min(cropY, pixelHeight - 1)),
            width: min(cropWidth, pixelWidth - max(0, cropX)),
            height: min(cropHeight, pixelHeight - max(0, cropY))
        )
    }
    
    func extractKey(from text: String) -> String {
        text.components(separatedBy: "-")
            .first?
            .trimmingCharacters(in: .whitespaces)
            .uppercased() ?? ""
    }
}

enum OCRError: LocalizedError {
    case invalidImage
    case croppingFailed
    case noResults
    
    var errorDescription: String? {
        switch self {
        case .invalidImage: return "Invalid image"
        case .croppingFailed: return "Failed to crop image"
        case .noResults: return "No text found"
        }
    }
}

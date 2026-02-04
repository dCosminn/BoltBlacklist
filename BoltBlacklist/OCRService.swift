import UIKit
import Vision

class OCRService {
    static let shared = OCRService()
    
    func recognizeText(in image: UIImage, rect: CGRect, imageDisplayRect: CGRect, completion: @escaping (Result<String, Error>) -> Void) {
        guard let cgImage = image.cgImage else {
            completion(.failure(OCRError.invalidImage))
            return
        }
        
        // Calculate crop rectangle in image coordinates
        let cropRect = calculateCropRect(
            overlayRect: rect,
            imageSize: image.size,
            displayRect: imageDisplayRect
        )
        
        guard let croppedImage = cgImage.cropping(to: cropRect) else {
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
        
        let handler = VNImageRequestHandler(cgImage: croppedImage, options: [:])
        DispatchQueue.global(qos: .userInitiated).async {
            try? handler.perform([request])
        }
    }
    
    private func calculateCropRect(
        overlayRect: CGRect,
        imageSize: CGSize,
        displayRect: CGRect
    ) -> CGRect {

        // 1. Determine scale used by .scaledToFit
        let scale = min(
            displayRect.width / imageSize.width,
            displayRect.height / imageSize.height
        )

        let scaledImageSize = CGSize(
            width: imageSize.width * scale,
            height: imageSize.height * scale
        )

        // 2. Calculate letterbox offsets
        let xOffset = (displayRect.width - scaledImageSize.width) / 2
        let yOffset = (displayRect.height - scaledImageSize.height) / 2

        // 3. Convert overlay rect → image-local space
        let imageX = (overlayRect.minX - xOffset) / scale
        let imageY = (overlayRect.minY - yOffset) / scale
        let imageWidth = overlayRect.width / scale
        let imageHeight = overlayRect.height / scale

        // 4. Clamp safely to image bounds
        return CGRect(
            x: max(0, min(imageX, imageSize.width)),
            y: max(0, min(imageY, imageSize.height)),
            width: min(imageWidth, imageSize.width - imageX),
            height: min(imageHeight, imageSize.height - imageY)
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

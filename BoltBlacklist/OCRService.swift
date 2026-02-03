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
    
    private func calculateCropRect(overlayRect: CGRect, imageSize: CGSize, displayRect: CGRect) -> CGRect {
        let scaleX = imageSize.width / displayRect.width
        let scaleY = imageSize.height / displayRect.height
        
        let x = (overlayRect.minX - displayRect.minX) * scaleX
        let y = (overlayRect.minY - displayRect.minY) * scaleY
        let width = overlayRect.width * scaleX
        let height = overlayRect.height * scaleY
        
        return CGRect(
            x: max(0, min(x, imageSize.width)),
            y: max(0, min(y, imageSize.height)),
            width: min(width, imageSize.width - max(0, x)),
            height: min(height, imageSize.height - max(0, y))
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

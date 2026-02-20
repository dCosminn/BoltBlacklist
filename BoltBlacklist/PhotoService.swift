import Photos
import UIKit

class PhotoService {
    static let shared = PhotoService()
    
    func getLatestScreenshot(completion: @escaping (UIImage?) -> Void) {
        // Check permission
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        
        if status == .authorized || status == .limited {
            fetchLatestScreenshot(completion: completion)
        } else if status == .notDetermined {
            // Request permission
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { newStatus in
                if newStatus == .authorized || newStatus == .limited {
                    self.fetchLatestScreenshot(completion: completion)
                } else {
                    completion(nil)
                }
            }
        } else {
            completion(nil)
        }
    }
    
    private func fetchLatestScreenshot(completion: @escaping (UIImage?) -> Void) {
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        fetchOptions.fetchLimit = 1
        
        // Fetch screenshots
        let screenshots = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        
        guard let asset = screenshots.firstObject else {
            completion(nil)
            return
        }
        
        // Load the image
        let options = PHImageRequestOptions()
        options.isSynchronous = false
        options.deliveryMode = .highQualityFormat
        
        PHImageManager.default().requestImage(
            for: asset,
            targetSize: PHImageManagerMaximumSize,
            contentMode: .aspectFit,
            options: options
        ) { image, _ in
            completion(image)
        }
    }
}

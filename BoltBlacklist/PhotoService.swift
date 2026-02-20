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
                    print("Photos permission denied")
                    completion(nil)
                }
            }
        } else {
            print("Photos permission not granted: \(status.rawValue)")
            completion(nil)
        }
    }
    
    private func fetchLatestScreenshot(completion: @escaping (UIImage?) -> Void) {
        // Fetch directly from Screenshots album
        let screenshotsAlbum = PHAssetCollection.fetchAssetCollections(
            with: .smartAlbum,
            subtype: .smartAlbumScreenshots,
            options: nil
        )
        
        guard let screenshots = screenshotsAlbum.firstObject else {
            print("Screenshots album not found")
            completion(nil)
            return
        }
        
        // Fetch assets from Screenshots album
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        fetchOptions.fetchLimit = 1  // Only get the most recent
        
        let assets = PHAsset.fetchAssets(in: screenshots, options: fetchOptions)
        
        guard let latestScreenshot = assets.firstObject else {
            print("No screenshots found")
            completion(nil)
            return
        }
        
        print("Found screenshot: \(latestScreenshot.pixelWidth)x\(latestScreenshot.pixelHeight)")
        
        // Load the image
        let options = PHImageRequestOptions()
        options.isSynchronous = false
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
        
        PHImageManager.default().requestImage(
            for: latestScreenshot,
            targetSize: PHImageManagerMaximumSize,
            contentMode: .aspectFit,
            options: options
        ) { image, info in
            if let image = image {
                print("Loaded screenshot successfully")
                completion(image)
            } else {
                print("Failed to load screenshot")
                completion(nil)
            }
        }
    }
    func getLatestScreenshotWithIdentifier(completion: @escaping (UIImage?, String?) -> Void) {

        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)

        guard status == .authorized else {
            completion(nil, nil)
            return
        }

        let screenshotsAlbum = PHAssetCollection.fetchAssetCollections(
            with: .smartAlbum,
            subtype: .smartAlbumScreenshots,
            options: nil
        )

        guard let screenshots = screenshotsAlbum.firstObject else {
            completion(nil, nil)
            return
        }

        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        fetchOptions.fetchLimit = 1

        let assets = PHAsset.fetchAssets(in: screenshots, options: fetchOptions)

        guard let latestScreenshot = assets.firstObject else {
            completion(nil, nil)
            return
        }

        let identifier = latestScreenshot.localIdentifier

        PHImageManager.default().requestImage(
            for: latestScreenshot,
            targetSize: PHImageManagerMaximumSize,
            contentMode: .aspectFit,
            options: nil
        ) { image, _ in
            completion(image, identifier)
        }
    }
}

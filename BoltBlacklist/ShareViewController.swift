import UIKit
import Social
import UniformTypeIdentifiers

class ShareViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        handleSharedContent()
    }
    
    private func handleSharedContent() {
        guard let extensionItem = extensionContext?.inputItems.first as? NSExtensionItem,
              let itemProvider = extensionItem.attachments?.first else {
            closeExtension()
            return
        }
        
        let imageType = UTType.image.identifier
        
        if itemProvider.hasItemConformingToTypeIdentifier(imageType) {
            itemProvider.loadItem(forTypeIdentifier: imageType, options: nil) { [weak self] (item, error) in
                guard error == nil else {
                    self?.closeExtension()
                    return
                }
                
                var imageToShare: UIImage?
                
                if let url = item as? URL {
                    imageToShare = UIImage(contentsOfFile: url.path)
                } else if let data = item as? Data {
                    imageToShare = UIImage(data: data)
                } else if let image = item as? UIImage {
                    imageToShare = image
                }
                
                if let image = imageToShare {
                    self?.saveImageAndOpenMainApp(image)
                } else {
                    self?.closeExtension()
                }
            }
        } else {
            closeExtension()
        }
    }
    
    private func saveImageAndOpenMainApp(_ image: UIImage) {
        // Save image temporarily
        let tempDir = FileManager.default.temporaryDirectory
        let imageURL = tempDir.appendingPathComponent("shared_image_\(UUID().uuidString).jpg")
        
        if let data = image.jpegData(compressionQuality: 0.9) {
            try? data.write(to: imageURL)
            
            // Open main app with custom URL scheme
            DispatchQueue.main.async { [weak self] in
                if let url = URL(string: "boltblacklist://share?image=\(imageURL.absoluteString)") {
                    self?.openURL(url)
                }
                
                // Delay closing to allow URL to be processed
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self?.closeExtension()
                }
            }
        } else {
            closeExtension()
        }
    }
    
    @objc private func openURL(_ url: URL) {
        var responder: UIResponder? = self
        while responder != nil {
            if let application = responder as? UIApplication {
                application.perform(#selector(openURL(_:)), with: url)
                return
            }
            responder = responder?.next
        }
    }
    
    private func closeExtension() {
        extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
    }
}

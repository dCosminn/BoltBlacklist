import SwiftUI
import Combine

class AppCoordinator: ObservableObject {
    @Published var sharedImage: UIImage?
    @Published var shouldRunOCR = false
    
    func handleURL(_ url: URL) {
        if url.scheme == "boltblacklist" {
            handleShareURL(url)
        } else {
            loadImage(from: url)
        }
    }
    
    private func handleShareURL(_ url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let imageURLString = components.queryItems?.first(where: { $0.name == "image" })?.value,
              let imageURL = URL(string: imageURLString) else {
            return
        }
        loadImage(from: imageURL)
    }
    
    private func loadImage(from url: URL) {
        guard let data = try? Data(contentsOf: url),
              let image = UIImage(data: data) else {
            return
        }
        
        DispatchQueue.main.async {
            self.sharedImage = image
            self.shouldRunOCR = true
        }
    }
}

import SwiftUI

@main
struct BoltBlacklistApp: App {
    @StateObject private var appCoordinator = AppCoordinator()
    
    var body: some Scene {
        WindowGroup {
            MainView()
                .environmentObject(appCoordinator)
                .onOpenURL { url in
                    appCoordinator.handleURL(url)
                }
        }
    }
}

import SwiftUI

@main
struct IGotThisApp: App {
    var body: some Scene {
        WindowGroup {
            WebHost().ignoresSafeArea()
        }
    }
}

struct WebHost: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> WebViewController { WebViewController() }
    func updateUIViewController(_ uiViewController: WebViewController, context: Context) {}
}

import Foundation
import WebKit

/// Serves the bundled page from igotthis://app/... so it has a stable origin (and so its
/// localStorage is kept between launches) without any network or file:// access.
final class AssetSchemeHandler: NSObject, WKURLSchemeHandler {
    static let scheme = "igotthis"
    static let startURL = URL(string: "igotthis://app/index.html")!

    private let root: URL

    override init() {
        root = (Bundle.main.resourceURL ?? Bundle.main.bundleURL)
            .appendingPathComponent("Web", isDirectory: true)
            .standardizedFileURL
        super.init()
    }

    func webView(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
        guard let url = urlSchemeTask.request.url else {
            urlSchemeTask.didFailWithError(URLError(.badURL))
            return
        }
        var path = url.path
        if path.isEmpty || path == "/" { path = "/index.html" }
        let file = root.appendingPathComponent(String(path.dropFirst())).standardizedFileURL

        // Stay inside the Web folder.
        guard file.path.hasPrefix(root.path + "/"),
              let data = try? Data(contentsOf: file) else {
            respond(urlSchemeTask, url: url, status: 404, type: "text/plain", data: Data())
            return
        }
        respond(urlSchemeTask, url: url, status: 200, type: mime(for: file.pathExtension), data: data)
    }

    func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) {}

    private func respond(_ task: WKURLSchemeTask, url: URL, status: Int, type: String, data: Data) {
        let headers = [
            "Content-Type": type,
            "Content-Length": String(data.count),
            "Cache-Control": "no-cache"
        ]
        let response = HTTPURLResponse(url: url, statusCode: status, httpVersion: "HTTP/1.1", headerFields: headers)!
        task.didReceive(response)
        task.didReceive(data)
        task.didFinish()
    }

    private func mime(for ext: String) -> String {
        switch ext.lowercased() {
        case "html", "htm": return "text/html; charset=utf-8"
        case "js": return "text/javascript; charset=utf-8"
        case "css": return "text/css; charset=utf-8"
        case "json": return "application/json"
        case "png": return "image/png"
        case "jpg", "jpeg": return "image/jpeg"
        case "svg": return "image/svg+xml"
        default: return "application/octet-stream"
        }
    }
}

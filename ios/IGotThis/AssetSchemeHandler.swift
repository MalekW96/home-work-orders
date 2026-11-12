import Foundation
import WebKit

/// Serves the bundled page from igotthis://app/... so it has a stable origin (and so its
/// localStorage is kept between launches) without any network or file:// access.
final class AssetSchemeHandler: NSObject, WKURLSchemeHandler {
    static let scheme = "igotthis"
    static let startURL = URL(string: "igotthis://app/index.html")!

    private let root: URL
    private let updated: URL

    /// Where a downloaded update of the page is kept. It is used instead of the bundled page
    /// until a newer build of the app is installed.
    static var updateFolder: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return base.appendingPathComponent("WebUpdate", isDirectory: true).standardizedFileURL
    }

    static func version(inPageAt url: URL) -> [Int]? {
        guard let data = try? Data(contentsOf: url), let text = String(data: data, encoding: .utf8),
              let r = text.range(of: "APP_VERSION='[0-9.]+'", options: .regularExpression) else { return nil }
        let v = text[r].dropFirst("APP_VERSION='".count).dropLast()
        return v.split(separator: ".").compactMap { Int($0) }
    }

    static func isNewer(_ a: [Int], than b: [Int]) -> Bool {
        for i in 0..<max(a.count, b.count) {
            let x = i < a.count ? a[i] : 0, y = i < b.count ? b[i] : 0
            if x != y { return x > y }
        }
        return false
    }

    override init() {
        root = (Bundle.main.resourceURL ?? Bundle.main.bundleURL)
            .appendingPathComponent("Web", isDirectory: true)
            .standardizedFileURL
        updated = AssetSchemeHandler.updateFolder
        super.init()
        // Forget a downloaded page once the installed app is as new or newer.
        let fm = FileManager.default
        if fm.fileExists(atPath: updated.path) {
            let bundled = AssetSchemeHandler.version(inPageAt: root.appendingPathComponent("index.html")) ?? [0]
            if let u = AssetSchemeHandler.version(inPageAt: updated.appendingPathComponent("index.html")),
               AssetSchemeHandler.isNewer(u, than: bundled) {
                // keep it
            } else {
                try? fm.removeItem(at: updated)
            }
        }
    }

    func webView(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
        guard let url = urlSchemeTask.request.url else {
            urlSchemeTask.didFailWithError(URLError(.badURL))
            return
        }
        var path = url.path
        if path.isEmpty || path == "/" { path = "/index.html" }
        let rel = String(path.dropFirst())
        var base = root
        if FileManager.default.fileExists(atPath: updated.appendingPathComponent(rel).path) { base = updated }
        let file = base.appendingPathComponent(rel).standardizedFileURL

        // Stay inside the Web (or update) folder.
        guard file.path.hasPrefix(base.path + "/"),
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

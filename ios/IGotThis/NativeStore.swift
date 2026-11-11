import Foundation

/// A second copy of the page's records, kept in a file in the app's own storage.
/// iOS can clear a web view's localStorage when the phone runs very low on space;
/// this copy is put back if that ever happens. It lives and dies with the app, like the page's own data.
enum NativeStore {
    private static var fileURL: URL {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("records.json")
    }

    static func read() -> String? {
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func write(_ json: String) {
        guard let data = json.data(using: .utf8) else { return }
        try? data.write(to: fileURL, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
    }
}

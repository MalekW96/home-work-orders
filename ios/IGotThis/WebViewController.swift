import UIKit
import WebKit
import CoreLocation
import UserNotifications

/// Hosts the I Got This page in a WKWebView. The page talks to the app through `window.IOSBridge`
/// (defined by the script below), only to hand files to the share sheet and to keep a native copy of the records.
final class WebViewController: UIViewController, WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler,
    UNUserNotificationCenterDelegate, CLLocationManagerDelegate {

    private var webView: WKWebView!
    private var wantsLocation = false
    private lazy var locator: CLLocationManager = {
        let m = CLLocationManager()
        m.delegate = self
        m.desiredAccuracy = kCLLocationAccuracyBest
        return m
    }()

    private static let background = UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 0x0E / 255, green: 0x13 / 255, blue: 0x1A / 255, alpha: 1)
            : UIColor(red: 0xEE / 255, green: 0xF1 / 255, blue: 0xF4 / 255, alpha: 1)
    }

    /// Holds the controller weakly so the web view's content controller does not keep it alive.
    private final class Relay: NSObject, WKScriptMessageHandler {
        weak var target: WKScriptMessageHandler?
        init(_ target: WKScriptMessageHandler) { self.target = target }
        func userContentController(_ c: WKUserContentController, didReceive message: WKScriptMessage) {
            target?.userContentController(c, didReceive: message)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Self.background
        UNUserNotificationCenter.current().delegate = self

        let config = WKWebViewConfiguration()
        config.setURLSchemeHandler(AssetSchemeHandler(), forURLScheme: AssetSchemeHandler.scheme)
        config.allowsInlineMediaPlayback = true
        config.userContentController.addUserScript(
            WKUserScript(source: bridgeScript(), injectionTime: .atDocumentStart, forMainFrameOnly: true)
        )
        config.userContentController.add(Relay(self), name: "ios")

        webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.isOpaque = false
        webView.backgroundColor = Self.background
        webView.scrollView.backgroundColor = Self.background
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.scrollView.bounces = false
        webView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(webView)
        // Keep the page clear of the notch, the Dynamic Island and the home indicator.
        let guide = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: guide.topAnchor, constant: 8),
            webView.bottomAnchor.constraint(equalTo: guide.bottomAnchor),
            webView.leadingAnchor.constraint(equalTo: guide.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: guide.trailingAnchor)
        ])

        // Swipe in from the left edge = the Back button on Android.
        let edge = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(edgeSwipe(_:)))
        edge.edges = .left
        view.addGestureRecognizer(edge)

        webView.load(URLRequest(url: AssetSchemeHandler.startURL))
    }

    @objc private func edgeSwipe(_ g: UIScreenEdgePanGestureRecognizer) {
        guard g.state == .ended else { return }
        webView.evaluateJavaScript("window.__back && window.__back()", completionHandler: nil)
    }

    // MARK: Bridge script

    private func bridgeScript() -> String {
        let saved = NativeStore.read()
        let literal: String
        if let saved = saved, let data = try? JSONEncoder().encode(saved), let s = String(data: data, encoding: .utf8) {
            literal = s
        } else {
            literal = "null"
        }
        return """
        (function(){
          var KEY='hwo:db:v1';
          var native=\(literal);
          try{ if(native!==null && !window.localStorage.getItem(KEY)) window.localStorage.setItem(KEY,native); }catch(e){}
          var post=function(m){ try{ window.webkit.messageHandlers.ios.postMessage(m); }catch(e){} };
          var timer=null;
          var orig=Storage.prototype.setItem;
          Storage.prototype.setItem=function(k,v){
            orig.call(this,k,v);
            if(k===KEY){ clearTimeout(timer); timer=setTimeout(function(){ post({t:'persist',v:String(v)}); },800); }
          };
          document.addEventListener('visibilitychange',function(){
            if(document.hidden){ try{ var v=window.localStorage.getItem(KEY); if(v!==null) post({t:'persist',v:v}); }catch(e){} }
          });
          window.IOSBridge={
            saveFile:function(name,b64){ post({t:'save',name:String(name),data:String(b64)}); return 'ok'; },
            setReminders:function(json){ post({t:'reminders',v:String(json)}); return 'ok'; },
            requestLocation:function(){ post({t:'location'}); },
            updateContent:function(){ post({t:'update'}); }
          };
        })();
        """
    }

    // MARK: Messages from the page

    func userContentController(_ c: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let body = message.body as? [String: Any], let kind = body["t"] as? String else { return }
        switch kind {
        case "persist":
            if let json = body["v"] as? String { NativeStore.write(json) }
        case "save":
            if let name = body["name"] as? String, let b64 = body["data"] as? String {
                share(name: name, base64: b64)
            }
        case "reminders":
            if let json = body["v"] as? String { scheduleReminders(json) }
        case "location":
            startLocation()
        case "update":
            updateContent()
        default:
            break
        }
    }

    // MARK: In-app update of the page

    /// Downloads the newest page (and its PDF libraries) from the project's web app and keeps it next to the app.
    private func updateContent() {
        let base = "https://malekw96.github.io/home-work-orders/"
        let files = ["index.html", "libs/jspdf.umd.min.js", "libs/jspdf.plugin.autotable.min.js"]
        Task {
            var failure: String? = nil
            let fm = FileManager.default
            let staging = fm.temporaryDirectory.appendingPathComponent("webupdate-" + UUID().uuidString, isDirectory: true)
            do {
                for f in files {
                    var req = URLRequest(url: URL(string: base + f)!)
                    req.cachePolicy = .reloadIgnoringLocalCacheData
                    req.timeoutInterval = 30
                    let (data, resp) = try await URLSession.shared.data(for: req)
                    guard (resp as? HTTPURLResponse)?.statusCode == 200, !data.isEmpty else {
                        throw URLError(.badServerResponse)
                    }
                    let dest = staging.appendingPathComponent(f)
                    try fm.createDirectory(at: dest.deletingLastPathComponent(), withIntermediateDirectories: true)
                    try data.write(to: dest)
                }
                guard AssetSchemeHandler.version(inPageAt: staging.appendingPathComponent("index.html")) != nil else {
                    throw URLError(.cannotParseResponse)
                }
                let target = AssetSchemeHandler.updateFolder
                try fm.createDirectory(at: target.deletingLastPathComponent(), withIntermediateDirectories: true)
                try? fm.removeItem(at: target)
                try fm.moveItem(at: staging, to: target)
            } catch {
                try? fm.removeItem(at: staging)
                failure = "The update could not be downloaded. Check your connection and try again."
            }
            await MainActor.run {
                if let failure = failure {
                    let q = (try? JSONEncoder().encode(failure)).flatMap { String(data: $0, encoding: .utf8) } ?? "\"\""
                    self.webView.evaluateJavaScript("window.__iosUpdate && window.__iosUpdate(false,\(q))", completionHandler: nil)
                } else {
                    self.webView.evaluateJavaScript("window.__iosUpdate && window.__iosUpdate(true,'')", completionHandler: nil)
                }
            }
        }
    }

    // MARK: Follow-up reminders

    /// The page sends the full list each time its tasks change. Each item is {key, at (epoch ms), title, body}.
    private func scheduleReminders(_ json: String) {
        guard let data = json.data(using: .utf8),
              let items = (try? JSONSerialization.jsonObject(with: data)) as? [[String: Any]] else { return }
        let center = UNUserNotificationCenter.current()
        center.getPendingNotificationRequests { pending in
            // Replace everything this app scheduled before.
            let ours = pending.map { $0.identifier }.filter { $0.hasPrefix("hwo-") }
            center.removePendingNotificationRequests(withIdentifiers: ours)
            if items.isEmpty { return }
            center.requestAuthorization(options: [.alert, .sound]) { granted, _ in
                guard granted else { return }
                let now = Date().timeIntervalSince1970 * 1000
                for item in items {
                    guard let key = item["key"] as? String,
                          let at = (item["at"] as? NSNumber)?.doubleValue,
                          at > now else { continue }
                    let content = UNMutableNotificationContent()
                    content.title = "! " + (item["title"] as? String ?? "Follow-up needed")
                    content.body = item["body"] as? String ?? ""
                    content.sound = .default
                    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(1, (at - now) / 1000), repeats: false)
                    center.add(UNNotificationRequest(identifier: "hwo-" + key, content: content, trigger: trigger))
                }
            }
        }
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .list, .sound])
    }

    // MARK: Location (for "Save current location" on a task)

    private func startLocation() {
        wantsLocation = true
        switch locator.authorizationStatus {
        case .denied, .restricted:
            finishLocation(error: "Location is turned off for this app. Turn it on in Settings, then try again.")
        case .notDetermined:
            locator.requestWhenInUseAuthorization()
        default:
            locator.requestLocation()
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        guard wantsLocation else { return }
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()
        case .denied, .restricted:
            finishLocation(error: "Location is turned off for this app. Turn it on in Settings, then try again.")
        default:
            break
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard wantsLocation, let l = locations.last else { return }
        wantsLocation = false
        let js = "window.__locDone && window.__locDone(true,\(l.coordinate.latitude),\(l.coordinate.longitude),\(max(0, l.horizontalAccuracy)))"
        webView.evaluateJavaScript(js, completionHandler: nil)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        guard wantsLocation else { return }
        finishLocation(error: "The location could not be read. Try again with a better signal.")
    }

    private func finishLocation(error message: String) {
        wantsLocation = false
        let quoted = (try? JSONEncoder().encode(message)).flatMap { String(data: $0, encoding: .utf8) } ?? "\"\""
        webView.evaluateJavaScript("window.__locDone && window.__locDone(false,\(quoted))", completionHandler: nil)
    }

    private func share(name: String, base64: String) {
        guard let data = Data(base64Encoded: base64) else { return }
        let safe = name.replacingOccurrences(of: "[^A-Za-z0-9._-]", with: "_", options: .regularExpression)
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("exports", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let file = dir.appendingPathComponent(safe.isEmpty ? "export" : safe)
        do { try data.write(to: file, options: .atomic) } catch { return }

        let sheet = UIActivityViewController(activityItems: [file], applicationActivities: nil)
        sheet.popoverPresentationController?.sourceView = view
        sheet.popoverPresentationController?.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 1, height: 1)
        sheet.popoverPresentationController?.permittedArrowDirections = []
        sheet.completionWithItemsHandler = { _, _, _, _ in try? FileManager.default.removeItem(at: file) }
        present(sheet, animated: true)
    }

    // MARK: Navigation

    func webView(_ webView: WKWebView, decidePolicyFor action: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = action.request.url else { decisionHandler(.cancel); return }
        switch url.scheme {
        case AssetSchemeHandler.scheme, "about", "blob", "data":
            decisionHandler(.allow)
        case "http", "https", "mailto", "tel":
            UIApplication.shared.open(url)
            decisionHandler(.cancel)
        default:
            decisionHandler(.cancel)
        }
    }

    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration,
                 for action: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if let url = action.request.url, ["http", "https"].contains(url.scheme ?? "") {
            UIApplication.shared.open(url)
        }
        return nil
    }

    // MARK: JavaScript dialogs (WKWebView shows none unless the app does)

    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String,
                 initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        let a = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        a.addAction(UIAlertAction(title: "OK", style: .default) { _ in completionHandler() })
        present(a, animated: true)
    }

    func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String,
                 initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        let a = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        a.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in completionHandler(false) })
        a.addAction(UIAlertAction(title: "OK", style: .default) { _ in completionHandler(true) })
        present(a, animated: true)
    }
}

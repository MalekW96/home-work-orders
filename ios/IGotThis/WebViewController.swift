import UIKit
import WebKit

/// Hosts the I Got This page in a WKWebView. The page talks to the app through `window.IOSBridge`
/// (defined by the script below), only to hand files to the share sheet and to keep a native copy of the records.
final class WebViewController: UIViewController, WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler {

    private var webView: WKWebView!

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
          window.IOSBridge={ saveFile:function(name,b64){ post({t:'save',name:String(name),data:String(b64)}); return 'ok'; } };
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
        default:
            break
        }
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

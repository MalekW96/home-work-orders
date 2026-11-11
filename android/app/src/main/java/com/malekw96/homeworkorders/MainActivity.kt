package com.malekw96.homeworkorders

import android.annotation.SuppressLint
import android.content.ContentValues
import android.content.Intent
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import androidx.core.content.FileProvider
import java.io.File
import java.net.HttpURLConnection
import java.net.URL
import android.os.Bundle
import android.os.Environment
import android.provider.MediaStore
import android.util.Base64
import android.webkit.JavascriptInterface
import android.webkit.ValueCallback
import android.webkit.WebChromeClient
import android.webkit.WebResourceRequest
import android.webkit.WebResourceResponse
import android.webkit.WebView
import android.webkit.WebViewClient
import androidx.activity.OnBackPressedCallback
import androidx.activity.result.contract.ActivityResultContracts
import androidx.appcompat.app.AppCompatActivity
import androidx.core.view.ViewCompat
import androidx.core.view.WindowCompat
import androidx.core.view.WindowInsetsCompat
import androidx.webkit.WebSettingsCompat
import androidx.webkit.WebViewAssetLoader
import androidx.webkit.WebViewFeature

/**
 * Hosts the Home Work Orders page (assets/index.html) in a WebView.
 * Records live in the page's own storage on the phone. The page talks to the
 * app through the `AndroidBridge` object below, only to save files to Downloads.
 */
class MainActivity : AppCompatActivity() {

    private lateinit var webView: WebView
    private var fileCallback: ValueCallback<Array<Uri>>? = null

    private val picker = registerForActivityResult(
        ActivityResultContracts.StartActivityForResult()
    ) { result ->
        fileCallback?.onReceiveValue(
            WebChromeClient.FileChooserParams.parseResult(result.resultCode, result.data)
        )
        fileCallback = null
    }

    @SuppressLint("SetJavaScriptEnabled")
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        WindowCompat.setDecorFitsSystemWindows(window, false)

        webView = WebView(this)
        setContentView(webView)

        ViewCompat.setOnApplyWindowInsetsListener(webView) { v, insets ->
            val bars = insets.getInsets(
                WindowInsetsCompat.Type.systemBars() or
                    WindowInsetsCompat.Type.displayCutout() or
                    WindowInsetsCompat.Type.ime()
            )
            // Extra 60dp (about 1 cm) so the camera cutout never covers the header.
            val extraTop = (60 * resources.displayMetrics.density).toInt()
            v.setPadding(bars.left, bars.top + extraTop, bars.right, bars.bottom)
            WindowInsetsCompat.CONSUMED
        }

        webView.settings.apply {
            javaScriptEnabled = true
            domStorageEnabled = true
            allowFileAccess = false
        }
        if (WebViewFeature.isFeatureSupported(WebViewFeature.ALGORITHMIC_DARKENING)) {
            WebSettingsCompat.setAlgorithmicDarkeningAllowed(webView.settings, false)
        }

        val assetLoader = WebViewAssetLoader.Builder()
            .addPathHandler("/assets/", WebViewAssetLoader.AssetsPathHandler(this))
            .build()

        webView.webViewClient = object : WebViewClient() {
            override fun shouldInterceptRequest(
                view: WebView,
                request: WebResourceRequest
            ): WebResourceResponse? = assetLoader.shouldInterceptRequest(request.url)

            override fun shouldOverrideUrlLoading(
                view: WebView,
                request: WebResourceRequest
            ): Boolean {
                if (request.url.host == WebViewAssetLoader.DEFAULT_DOMAIN) return false
                try {
                    startActivity(Intent(Intent.ACTION_VIEW, request.url))
                } catch (_: Exception) {
                    // No app can open the link; stay on the page.
                }
                return true
            }
        }

        webView.webChromeClient = object : WebChromeClient() {
            override fun onShowFileChooser(
                webView: WebView,
                callback: ValueCallback<Array<Uri>>,
                params: FileChooserParams
            ): Boolean {
                fileCallback?.onReceiveValue(null)
                fileCallback = callback
                return try {
                    picker.launch(params.createIntent())
                    true
                } catch (_: Exception) {
                    fileCallback = null
                    false
                }
            }
        }

        webView.addJavascriptInterface(Bridge(), "AndroidBridge")

        val backCallback = object : OnBackPressedCallback(true) {
            override fun handleOnBackPressed() {
                webView.evaluateJavascript("(window.__back && window.__back()) === true") { handled ->
                    if (handled != "true") {
                        isEnabled = false
                        onBackPressedDispatcher.onBackPressed()
                    }
                }
            }
        }
        onBackPressedDispatcher.addCallback(this, backCallback)

        webView.loadUrl("https://${WebViewAssetLoader.DEFAULT_DOMAIN}/assets/index.html")
    }

    override fun onDestroy() {
        webView.destroy()
        super.onDestroy()
    }

    inner class Bridge {
        /** Saves a file to the phone's Downloads folder. Returns "ok" or an error message. */
        @JavascriptInterface
        fun saveFile(name: String, base64: String): String {
            return try {
                val bytes = Base64.decode(base64, Base64.DEFAULT)
                val safe = name.replace(Regex("[^A-Za-z0-9._-]"), "_")
                val mime = when {
                    safe.endsWith(".pdf") -> "application/pdf"
                    safe.endsWith(".csv") -> "text/csv"
                    safe.endsWith(".json") -> "application/json"
                    else -> "application/octet-stream"
                }
                val values = ContentValues().apply {
                    put(MediaStore.Downloads.DISPLAY_NAME, safe)
                    put(MediaStore.Downloads.MIME_TYPE, mime)
                    put(MediaStore.Downloads.RELATIVE_PATH, Environment.DIRECTORY_DOWNLOADS)
                }
                val uri = contentResolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, values)
                    ?: return "The file could not be created in Downloads."
                val out = contentResolver.openOutputStream(uri)
                    ?: return "The file could not be opened for writing."
                out.use { it.write(bytes) }
                "ok"
            } catch (e: Exception) {
                e.message ?: "The file could not be saved."
            }
        }
        /** Downloads the APK at [url] and opens Android's installer. Progress is reported to the page. */
        @JavascriptInterface
        fun installUpdate(url: String) {
            if (!url.startsWith("https://github.com/MalekW96/home-work-orders/")) {
                notifyPage("error", "Unexpected update address.")
                return
            }
            if (!packageManager.canRequestPackageInstalls()) {
                runOnUiThread {
                    try {
                        startActivity(
                            Intent(Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES, Uri.parse("package:$packageName"))
                        )
                    } catch (_: Exception) { }
                }
                notifyPage("permission", "Allow installs from this app, then press Download and install again.")
                return
            }
            Thread {
                try {
                    val dir = File(cacheDir, "updates").apply { mkdirs() }
                    val file = File(dir, "update.apk")
                    var conn = URL(url).openConnection() as HttpURLConnection
                    conn.instanceFollowRedirects = true
                    conn.connectTimeout = 15000
                    conn.readTimeout = 30000
                    var code = conn.responseCode
                    var hops = 0
                    while (code in 300..399 && hops < 5) {
                        val next = conn.getHeaderField("Location") ?: break
                        conn.disconnect()
                        conn = URL(next).openConnection() as HttpURLConnection
                        conn.connectTimeout = 15000
                        conn.readTimeout = 30000
                        code = conn.responseCode
                        hops++
                    }
                    if (code != 200) {
                        notifyPage("error", "The download failed (HTTP $code).")
                        return@Thread
                    }
                    val total = conn.contentLengthLong
                    var done = 0L
                    var lastPct = -1
                    conn.inputStream.use { input ->
                        file.outputStream().use { out ->
                            val buf = ByteArray(32 * 1024)
                            while (true) {
                                val n = input.read(buf)
                                if (n < 0) break
                                out.write(buf, 0, n)
                                done += n
                                if (total > 0) {
                                    val pct = (done * 100 / total).toInt()
                                    if (pct != lastPct) { lastPct = pct; notifyPage("progress", pct.toString()) }
                                }
                            }
                        }
                    }
                    val uri = FileProvider.getUriForFile(this@MainActivity, "$packageName.files", file)
                    val intent = Intent(Intent.ACTION_VIEW).apply {
                        setDataAndType(uri, "application/vnd.android.package-archive")
                        addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_ACTIVITY_NEW_TASK)
                    }
                    notifyPage("ready", "Download finished. Confirm the install on the next screen.")
                    runOnUiThread { startActivity(intent) }
                } catch (e: Exception) {
                    notifyPage("error", e.message ?: "The download failed.")
                }
            }.start()
        }
    }

    private fun notifyPage(state: String, msg: String) {
        val js = "window.__upd && window.__upd(" + org.json.JSONObject.quote(state) + "," + org.json.JSONObject.quote(msg) + ")"
        Handler(Looper.getMainLooper()).post { webView.evaluateJavascript(js, null) }
    }
}

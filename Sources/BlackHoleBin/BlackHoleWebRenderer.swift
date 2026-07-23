import Foundation
import WebKit

@MainActor
final class BlackHoleWebRenderer: NSObject, WKScriptMessageHandler {
    let webView: WKWebView
    private let messageProxy: WeakScriptMessageHandler

    var hoverTarget: Float = 0 {
        didSet { sendInteraction() }
    }
    var dragVector = SIMD2<Float>(repeating: 0) {
        didSet { sendInteraction() }
    }
    var reduceMotion = UserDefaults.standard.bool(forKey: Defaults.reduceMotion) {
        didSet {
            evaluate("window.blackHoleSetReducedMotion(\(reduceMotion ? "true" : "false"))")
        }
    }

    private(set) var isReady = false
    private(set) var lastError: String?

    override init() {
        let configuration = WKWebViewConfiguration()
        let proxy = WeakScriptMessageHandler()
        configuration.userContentController.add(proxy, name: "blackHoleLog")
        messageProxy = proxy
        webView = PassthroughWebView(frame: .zero, configuration: configuration)
        super.init()
        proxy.target = self

        webView.setValue(false, forKey: "drawsBackground")
        webView.underPageBackgroundColor = .clear
        webView.isHidden = false
        loadRenderer()
    }

    func triggerSuction() {
        evaluate("window.blackHolePulse('suction')")
    }

    func triggerSuccess() {
        evaluate("window.blackHolePulse('success')")
    }

    func triggerError() {
        evaluate("window.blackHolePulse('error')")
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        let value = String(describing: message.body)
        if value == "ready" {
            isReady = true
            sendInteraction()
            evaluate("window.blackHoleSetReducedMotion(\(reduceMotion ? "true" : "false"))")
        } else {
            lastError = value
            NSLog("BlackHoleBin WebGL: \(value)")
        }
    }

    private func loadRenderer() {
        do {
            let resources = RendererResources.bundle
            guard
                let shaderURL = resources.url(forResource: "blackhole", withExtension: "glsl"),
                let htmlURL = resources.url(forResource: "blackhole", withExtension: "html")
            else {
                throw CocoaError(.fileNoSuchFile)
            }

            let shader = try String(contentsOf: shaderURL, encoding: .utf8)
            let template = try String(contentsOf: htmlURL, encoding: .utf8)
            let encodedShader = String(
                data: try JSONEncoder().encode(shader),
                encoding: .utf8
            ) ?? "\"\""
            let html = template.replacingOccurrences(of: "__SHADER_JSON__", with: encodedShader)
            webView.loadHTMLString(html, baseURL: resources.bundleURL)
        } catch {
            NSLog("BlackHoleBin: unable to load upstream renderer: \(error)")
        }
    }

    private func sendInteraction() {
        evaluate(
            "window.blackHoleSetInteraction(\(hoverTarget), \(dragVector.x), \(dragVector.y))"
        )
    }

    private func evaluate(_ javascript: String) {
        guard isReady else { return }
        webView.evaluateJavaScript(javascript) { _, error in
            if let error {
                NSLog("BlackHoleBin WebGL bridge: \(error)")
            }
        }
    }
}

private enum RendererResources {
    static let bundle: Bundle = {
        if let resourceURL = Bundle.main.resourceURL {
            let packagedURL = resourceURL.appendingPathComponent("BlackHoleBin_BlackHoleBin.bundle")
            if let packagedBundle = Bundle(url: packagedURL) {
                return packagedBundle
            }
        }
        return Bundle.module
    }()
}

private final class PassthroughWebView: WKWebView {
    override func hitTest(_ point: NSPoint) -> NSView? {
        nil
    }
}

private final class WeakScriptMessageHandler: NSObject, WKScriptMessageHandler {
    weak var target: (any WKScriptMessageHandler)?

    func userContentController(
        _ userContentController: WKUserContentController,
        didReceive message: WKScriptMessage
    ) {
        target?.userContentController(userContentController, didReceive: message)
    }
}

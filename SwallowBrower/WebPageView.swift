//
//  WebPageView.swift
//  bluePage
//
//  Created by thking on 2026/4/11.
//

import SwiftUI
import WebKit
import AppKit
import Combine

// MARK: - PageColorExtractor
class PageColorExtractor: ObservableObject {
    @Published var extractedColor: Color = .gray.opacity(0.15)
    
    private var isEnabled = true
    private var currentExtractionKey: UUID?
    
    func start() {
        isEnabled = true
    }
    
    func extractColor(from url: URL, forViewId viewId: UUID) {
        guard isEnabled else { return }
        
        let key = UUID()
        currentExtractionKey = key
        
        ColorExtractionTask.start(url: url, viewId: viewId) { [weak self] colors, extractedViewId in
            DispatchQueue.main.async {
                guard let self = self, self.isEnabled else { return }
                guard self.currentExtractionKey == key else { return }
                if let dominant = colors.first {
                    self.extractedColor = Color(dominant)
                }
            }
        }
    }
    
    func isValidViewId(_ viewId: UUID) -> Bool {
        return isEnabled
    }
    
    func updateColor(from colors: [NSColor], forViewId viewId: UUID) {
        guard isEnabled, currentExtractionKey != nil else { return }
        if let dominant = colors.first {
            extractedColor = Color(dominant)
        }
    }
    
    func stop() {
        isEnabled = false
        currentExtractionKey = nil
        ColorExtractionTask.cancelAll()
    }
}

// MARK: - ColorExtractionTask
class ColorExtractionTask: NSObject, WKNavigationDelegate {
    let viewId: UUID
    private var webView: WKWebView?
    private var completion: (([NSColor], UUID) -> Void)?
    private var hasCompleted = false
    
    static var activeTasks: [ColorExtractionTask] = []
    static let queue = DispatchQueue(label: "com.fetchgithub.colorextraction")
    
    static func start(url: URL, viewId: UUID, completion: @escaping ([NSColor], UUID) -> Void) {
        let task = ColorExtractionTask(viewId: viewId, completion: completion)
        activeTasks.append(task)
        task.start(url: url)
    }
    
    static func cancelAll() {
        activeTasks.forEach { $0.cancel() }
        activeTasks.removeAll()
    }
    
    init(viewId: UUID, completion: @escaping ([NSColor], UUID) -> Void) {
        self.viewId = viewId
        self.completion = completion
        super.init()
    }
    
    func cancel() {
        hasCompleted = true
        webView?.stopLoading()
        webView = nil
    }
    
    private func start(url: URL) {
        let wkConfig = WKWebViewConfiguration()
        wkConfig.applicationNameForUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)"
        
        let frame = NSRect(x: 0, y: 0, width: 800, height: 600)
        let webview = WKWebView(frame: frame, configuration: wkConfig)
        webview.navigationDelegate = self
        webview.isHidden = true
        self.webView = webview
        
        let request = URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad, timeoutInterval: 15.0)
        webview.load(request)
        
        // 超时处理
        DispatchQueue.main.asyncAfter(deadline: .now() + 15.0) { [weak self] in
            self?.captureAndExtract()
        }
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.captureAndExtract()
        }
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        cleanup()
    }
    
    private func captureAndExtract() {
        guard !hasCompleted, let webView = webView else { return }
        
        let config = WKSnapshotConfiguration()
        config.afterScreenUpdates = true
        
        webView.takeSnapshot(with: config) { [weak self] image, _ in
            guard let self = self, !self.hasCompleted, let image = image else { return }
            self.hasCompleted = true
            
            let colors = self.extractDominantColors(from: image, topK: 3)
            self.cleanup()
            self.completion?(colors, self.viewId)
            
            // 从活跃任务列表中移除
            ColorExtractionTask.activeTasks.removeAll { $0 === self }
        }
    }
    
    private func cleanup() {
        webView?.stopLoading()
        webView = nil
    }
    
    private func extractDominantColors(from image: NSImage, topK: Int = 3) -> [NSColor] {
        guard let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData) else { return [] }
        
        var colorCounts: [UInt32: (r: UInt8, g: UInt8, b: UInt8, count: Int)] = [:]
        let step = 4
        let leftWidth = min(100, bitmap.pixelsWide)
        
        for x in stride(from: 0, to: leftWidth, by: step) {
            for y in stride(from: 0, to: bitmap.pixelsHigh, by: step) {
                guard let color = bitmap.colorAt(x: x, y: y),
                      color.alphaComponent > 0.8 else { continue }
                
                let r = UInt8(color.redComponent * 255)
                let g = UInt8(color.greenComponent * 255)
                let b = UInt8(color.blueComponent * 255)
                
                let qr = (r / 16) * 16
                let qg = (g / 16) * 16
                let qb = (b / 16) * 16
                let key = UInt32(qr) << 16 | UInt32(qg) << 8 | UInt32(qb)
                
                if var existing = colorCounts[key] {
                    existing.count += 1
                    colorCounts[key] = existing
                } else {
                    colorCounts[key] = (qr, qg, qb, 1)
                }
            }
        }
        
        let sortedColors = colorCounts.values.sorted { $0.count > $1.count }
        return sortedColors.prefix(topK).map { c in
            NSColor(calibratedRed: CGFloat(c.r) / 255.0,
                    green: CGFloat(c.g) / 255.0,
                    blue: CGFloat(c.b) / 255.0,
                    alpha: 1.0)
        }
    }
}

// MARK: - WebPageView
struct WebPageView: NSViewRepresentable {
    let viewId: UUID
    let url: String
    let colorExtractor: PageColorExtractor?

    init(viewId: UUID, url: String, colorExtractor: PageColorExtractor? = nil) {
        self.viewId = viewId
        self.url = url
        self.colorExtractor = colorExtractor
    }

    func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.preferences.javaScriptCanOpenWindowsAutomatically = true

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true
        webView.customUserAgent = UserDefaults.standard.string(forKey: "customUserAgent") ?? ""

        loadUrl(webView)
        return webView
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {
        // 检测 URL 是否改变，如果改变则重新加载
        if let currentUrl = nsView.url?.absoluteString {
            var newUrlString = url.trimmingCharacters(in: .whitespacesAndNewlines)
            if !newUrlString.hasPrefix("http://") && !newUrlString.hasPrefix("https://") {
                newUrlString = "https://" + newUrlString
            }
            if currentUrl != newUrlString {
                loadUrl(nsView)
            }
        } else {
            loadUrl(nsView)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(viewId: viewId, colorExtractor: colorExtractor)
    }

    private func loadUrl(_ webView: WKWebView) {
        var urlString = url.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !urlString.isEmpty else { return }

        if !urlString.hasPrefix("http://") && !urlString.hasPrefix("https://") {
            urlString = "https://" + urlString
        }

        if let finalUrl = URL(string: urlString) {
            webView.load(URLRequest(url: finalUrl))
            let extractor = colorExtractor
            let id = viewId
            DispatchQueue.main.async {
                extractor?.extractColor(from: finalUrl, forViewId: id)
            }
        }
    }

    class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
        let viewId: UUID
        weak var colorExtractor: PageColorExtractor?

        init(viewId: UUID, colorExtractor: PageColorExtractor?) {
            self.viewId = viewId
            self.colorExtractor = colorExtractor
        }

        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            decisionHandler(.allow)
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            guard let extractor = colorExtractor, extractor.isValidViewId(viewId) else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                guard let self = self, let extractor = self.colorExtractor, extractor.isValidViewId(self.viewId) else { return }
                self.captureAndExtract(webView: webView, extractor: extractor)
            }
        }
        
        func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
            if let url = navigationAction.request.url {
                webView.load(URLRequest(url: url))
            }
            return nil
        }
        
        private func captureAndExtract(webView: WKWebView, extractor: PageColorExtractor) {
            let config = WKSnapshotConfiguration()
            config.afterScreenUpdates = true
            
            webView.takeSnapshot(with: config) { image, _ in
                guard let image = image else { return }
                let colors = self.extractDominantColors(from: image, topK: 3)
                extractor.updateColor(from: colors, forViewId: self.viewId)
            }
        }
        
        private func extractDominantColors(from image: NSImage, topK: Int = 3) -> [NSColor] {
            guard let tiffData = image.tiffRepresentation,
                  let bitmap = NSBitmapImageRep(data: tiffData) else { return [] }
            
            var colorCounts: [UInt32: (r: UInt8, g: UInt8, b: UInt8, count: Int)] = [:]
            let step = 4
            let leftWidth = min(100, bitmap.pixelsWide)
            
            for x in stride(from: 0, to: leftWidth, by: step) {
                for y in stride(from: 0, to: bitmap.pixelsHigh, by: step) {
                    guard let color = bitmap.colorAt(x: x, y: y),
                          color.alphaComponent > 0.8 else { continue }
                    
                    let r = UInt8(color.redComponent * 255)
                    let g = UInt8(color.greenComponent * 255)
                    let b = UInt8(color.blueComponent * 255)
                    
                    let qr = (r / 16) * 16
                    let qg = (g / 16) * 16
                    let qb = (b / 16) * 16
                    let key = UInt32(qr) << 16 | UInt32(qg) << 8 | UInt32(qb)
                    
                    if var existing = colorCounts[key] {
                        existing.count += 1
                        colorCounts[key] = existing
                    } else {
                        colorCounts[key] = (qr, qg, qb, 1)
                    }
                }
            }
            
            let sortedColors = colorCounts.values.sorted { $0.count > $1.count }
            return sortedColors.prefix(topK).map { c in
                NSColor(calibratedRed: CGFloat(c.r) / 255.0,
                        green: CGFloat(c.g) / 255.0,
                        blue: CGFloat(c.b) / 255.0,
                        alpha: 1.0)
            }
        }
    }
}

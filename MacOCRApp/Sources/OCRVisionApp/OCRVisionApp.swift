import SwiftUI
import Vision
import AppKit
import Foundation
import CoreImage
import ApplicationServices

// MARK: - Models

enum ScanMode: String, CaseIterable, Identifiable {
    case partialCrop = "부분 크롭"
    case selectedUI = "선택한 곳"
    case programWindow = "프로그램 창"
    case fullScreen = "전체 화면"
    
    var id: String { rawValue }
    var icon: String {
        switch self {
        case .partialCrop: return "crop"
        case .selectedUI: return "hand.tap"
        case .programWindow: return "macwindow"
        case .fullScreen: return "desktopcomputer"
        }
    }
    var shortcut: String {
        switch self {
        case .partialCrop: return "⌘⇧1"
        case .selectedUI: return "⌘⇧2"
        case .programWindow: return "⌘⇧3"
        case .fullScreen: return "⌘⇧4"
        }
    }
}

struct OCRResult: Codable, Identifiable {
    let id = UUID()
    let text: String
    let confidence: Double
    let x: Int
    let y: Int
    let width: Int
    let height: Int
    var axRole: String?
    var uiType: String?
}

struct ScanResult: Codable {
    let timestamp: Date
    let mode: String
    let texts: [OCRResult]
    let imagePath: String?
}

// MARK: - OCR Engine

@MainActor
class OCREngine: ObservableObject {
    @Published var isProcessing = false
    @Published var lastResult: ScanResult?
    @Published var errorMessage: String?
    
    func performOCR(on image: NSImage, mode: ScanMode) async -> ScanResult? {
        isProcessing = true
        defer { isProcessing = false }
        
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            errorMessage = "이미지를 로드할 수 없습니다"
            return nil
        }
        
        let imageWidth = cgImage.width
        let imageHeight = cgImage.height
        
        do {
            let texts = try await recognizeText(in: cgImage, width: imageWidth, height: imageHeight)
            let result = ScanResult(
                timestamp: Date(),
                mode: mode.rawValue,
                texts: texts,
                imagePath: nil
            )
            lastResult = result
            copyToClipboard(texts: texts)
            return result
        } catch {
            errorMessage = "OCR 오류: \(error.localizedDescription)"
            return nil
        }
    }
    
    private func recognizeText(in cgImage: CGImage, width: Int, height: Int) async throws -> [OCRResult] {
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.recognitionLanguages = ["ko-KR", "en-US"]
        request.usesLanguageCorrection = true
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try handler.perform([request])
        
        guard let observations = request.results as? [VNRecognizedTextObservation] else {
            return []
        }
        
        return observations.compactMap { obs in
            guard let candidate = obs.topCandidates(1).first else { return nil }
            let bbox = obs.boundingBox
            return OCRResult(
                text: candidate.string,
                confidence: Double(candidate.confidence),
                x: Int(bbox.origin.x * CGFloat(width)),
                y: Int((1 - bbox.origin.y - bbox.height) * CGFloat(height)),
                width: Int(bbox.width * CGFloat(width)),
                height: Int(bbox.height * CGFloat(height))
            )
        }
    }
    
    private func copyToClipboard(texts: [OCRResult]) {
        let text = texts.map { $0.text }.joined(separator: "\n")
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }
}

// MARK: - UI Scanner

@MainActor
class UIScanner: ObservableObject {
    func scanApplication(named name: String) async -> [[String: Any]]? {
        let apps = NSWorkspace.shared.runningApplications
        guard let app = apps.first(where: { 
            $0.localizedName?.contains(name) ?? false || 
            $0.bundleIdentifier?.contains(name) ?? false 
        }) else {
            return nil
        }
        
        return scanAppByPID(app.processIdentifier)
    }
    
    private func scanAppByPID(_ pid: pid_t) -> [[String: Any]] {
        let appElement = AXUIElementCreateApplication(pid)
        var elements: [[String: Any]] = []
        
        var windowsValue: AnyObject?
        let err = AXUIElementCopyAttributeValue(appElement, kAXWindowsAttribute as CFString, &windowsValue)
        
        if err == .success, let windows = windowsValue as? [AXUIElement] {
            for window in windows {
                let info = getElementInfo(window, depth: 0, maxDepth: 2)
                elements.append(info)
            }
        }
        return elements
    }
    
    private func getElementInfo(_ element: AXUIElement, depth: Int, maxDepth: Int) -> [String: Any] {
        var roleValue: AnyObject?
        var titleValue: AnyObject?
        var valueAttr: AnyObject?
        var posValue: AnyObject?
        var sizeValue: AnyObject?
        
        AXUIElementCopyAttributeValue(element, kAXRoleAttribute as CFString, &roleValue)
        AXUIElementCopyAttributeValue(element, kAXTitleAttribute as CFString, &titleValue)
        AXUIElementCopyAttributeValue(element, kAXValueAttribute as CFString, &valueAttr)
        AXUIElementCopyAttributeValue(element, kAXPositionAttribute as CFString, &posValue)
        AXUIElementCopyAttributeValue(element, kAXSizeAttribute as CFString, &sizeValue)
        
        let role = roleValue as? String ?? ""
        let title = titleValue as? String ?? ""
        let value = valueAttr as? String ?? ""
        
        var pos = CGPoint.zero
        var size = CGSize.zero
        if let pv = posValue {
            var p = CGPoint()
            if AXValueGetValue(pv as! AXValue, .cgPoint, &p) { pos = p }
        }
        if let sv = sizeValue {
            var s = CGSize()
            if AXValueGetValue(sv as! AXValue, .cgSize, &s) { size = s }
        }
        
        var info: [String: Any] = [
            "role": role,
            "x": Int(pos.x),
            "y": Int(pos.y),
            "width": Int(size.width),
            "height": Int(size.height)
        ]
        if !title.isEmpty { info["title"] = title }
        if !value.isEmpty { info["value"] = value }
        
        if depth < maxDepth {
            var childrenValue: AnyObject?
            AXUIElementCopyAttributeValue(element, kAXChildrenAttribute as CFString, &childrenValue)
            if let childElements = childrenValue as? [AXUIElement] {
                let children = childElements.map { getElementInfo($0, depth: depth + 1, maxDepth: maxDepth) }
                if !children.isEmpty { info["children"] = children }
            }
        }
        return info
    }
}

// MARK: - Screenshot Manager

@MainActor
class ScreenshotManager: ObservableObject {
    func captureFullScreen() -> NSImage? {
        let screen = NSScreen.main!
        let rect = screen.frame
        return captureRect(rect)
    }
    
    func captureWindow(named windowName: String) -> NSImage? {
        let apps = NSWorkspace.shared.runningApplications
        for app in apps {
            let appElement = AXUIElementCreateApplication(app.processIdentifier)
            var windowsValue: AnyObject?
            AXUIElementCopyAttributeValue(appElement, kAXWindowsAttribute as CFString, &windowsValue)
            
            if let windows = windowsValue as? [AXUIElement] {
                for window in windows {
                    var titleValue: AnyObject?
                    AXUIElementCopyAttributeValue(window, kAXTitleAttribute as CFString, &titleValue)
                    if let title = titleValue as? String, title.contains(windowName) {
                        var posValue: AnyObject?
                        var sizeValue: AnyObject?
                        AXUIElementCopyAttributeValue(window, kAXPositionAttribute as CFString, &posValue)
                        AXUIElementCopyAttributeValue(window, kAXSizeAttribute as CFString, &sizeValue)
                        
                        var pos = CGPoint.zero
                        var size = CGSize.zero
                        if let pv = posValue {
                            var p = CGPoint()
                            if AXValueGetValue(pv as! AXValue, .cgPoint, &p) { pos = p }
                        }
                        if let sv = sizeValue {
                            var s = CGSize()
                            if AXValueGetValue(sv as! AXValue, .cgSize, &s) { size = s }
                        }
                        let rect = CGRect(x: pos.x, y: pos.y, width: size.width, height: size.height)
                        return captureRect(rect)
                    }
                }
            }
        }
        return nil
    }
    
    func captureRect(_ rect: CGRect) -> NSImage? {
        let id = CGWindowID(0)
        let imageRef = CGWindowListCreateImage(rect, .optionOnScreenOnly, id, .bestResolution)
        guard let cgImage = imageRef else { return nil }
        return NSImage(cgImage: cgImage, size: rect.size)
    }
}

// MARK: - Views

struct ScanModeButton: View {
    let mode: ScanMode
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: mode.icon)
                    .font(.system(size: 28))
                Text(mode.rawValue)
                    .font(.caption)
                    .multilineTextAlignment(.center)
                Text(mode.shortcut)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(width: 80, height: 80)
            .background(isSelected ? Color.accentColor.opacity(0.2) : Color.clear)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.accentColor : Color.secondary.opacity(0.3), lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ResultsView: View {
    let result: ScanResult
    @State private var selectedText: String = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: ScanMode.allCases.first { $0.rawValue == result.mode }?.icon ?? "doc.text")
                    .foregroundColor(.accentColor)
                Text(result.mode)
                    .font(.headline)
                Spacer()
                Text(result.timestamp, style: .time)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Divider()
            
            if result.texts.isEmpty {
                Text("인식된 텍스트가 없습니다")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                List(result.texts) { text in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(text.text)
                            .font(.body)
                        HStack {
                            Text("신뢰도: \(Int(text.confidence * 100))%")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            if let uiType = text.uiType {
                                Text(uiType)
                                    .font(.caption)
                                    .foregroundColor(.accentColor)
                            }
                            Spacer()
                            Text("(\(text.x), \(text.y))")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .frame(minHeight: 200)
            }
            
            HStack {
                Button("전체 복사") {
                    let allText = result.texts.map { $0.text }.joined(separator: "\n")
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(allText, forType: .string)
                }
                .keyboardShortcut("C", modifiers: .command)
                
                Button("JSON 저장") {
                    saveAsJSON(result: result)
                }
                
                Spacer()
                
                Text("\(result.texts.count)개 인식됨")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
    
    private func saveAsJSON(result: ScanResult) {
        let savePanel = NSSavePanel()
        savePanel.nameFieldStringValue = "ocr-result-\(Int(Date().timeIntervalSince1970)).json"
        savePanel.allowedContentTypes = [.json]
        
        if savePanel.runModal() == .OK, let url = savePanel.url {
            if let data = try? JSONEncoder().encode(result) {
                try? data.write(to: url)
            }
        }
    }
}

struct ContentView: View {
    @StateObject private var ocrEngine = OCREngine()
    @StateObject private var uiScanner = UIScanner()
    @StateObject private var screenshotManager = ScreenshotManager()
    
    @State private var selectedMode: ScanMode = .partialCrop
    @State private var isShowingCropOverlay = false
    @State private var selectedApp: String = ""
    @State private var availableApps: [String] = []
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Image(systemName: "text.viewfinder")
                    .font(.largeTitle)
                    .foregroundColor(.accentColor)
                Text("OCR Vision")
                    .font(.largeTitle)
                    .bold()
                Spacer()
                if ocrEngine.isProcessing {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            .padding(.horizontal)
            
            // Scan Modes
            Text("스캔 모드 선택")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
            
            HStack(spacing: 16) {
                ForEach(ScanMode.allCases) { mode in
                    ScanModeButton(
                        mode: mode,
                        isSelected: selectedMode == mode
                    ) {
                        selectedMode = mode
                    }
                }
            }
            
            Divider()
                .padding(.horizontal)
            
            // Action Area
            HStack(spacing: 16) {
                Button("스캔 시작") {
                    performScan()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(ocrEngine.isProcessing)
                
                if case .programWindow = selectedMode {
                    Picker("앱 선택", selection: $selectedApp) {
                        Text("앱 선택...").tag("")
                        ForEach(availableApps, id: \.self) { app in
                            Text(app).tag(app)
                        }
                    }
                    .frame(width: 150)
                    .onAppear {
                        loadAvailableApps()
                    }
                }
            }
            
            if let error = ocrEngine.errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
            }
            
            // Results
            if let result = ocrEngine.lastResult {
                ResultsView(result: result)
                    .padding(.horizontal)
            } else {
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text("스캔 결과가 여기에 표시됩니다")
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
        }
        .padding(.vertical)
        .frame(minWidth: 500, minHeight: 400)
    }
    
    private func loadAvailableApps() {
        let apps = NSWorkspace.shared.runningApplications
            .compactMap { $0.localizedName }
            .filter { !$0.isEmpty }
            .sorted()
        availableApps = apps
    }
    
    private func performScan() {
        Task {
            switch selectedMode {
            case .fullScreen:
                if let image = screenshotManager.captureFullScreen() {
                    _ = await ocrEngine.performOCR(on: image, mode: .fullScreen)
                }
                
            case .partialCrop:
                // Show crop overlay
                showCropOverlay()
                
            case .programWindow:
                if !selectedApp.isEmpty,
                   let image = screenshotManager.captureWindow(named: selectedApp) {
                    _ = await ocrEngine.performOCR(on: image, mode: .programWindow)
                }
                
            case .selectedUI:
                // UI element selection mode
                await performUIScan()
            }
        }
    }
    
    private func showCropOverlay() {
        // Implementation for crop overlay
        // Would create a full-screen transparent window for selection
    }
    
    private func performUIScan() async {
        // Scan frontmost app
        if let frontmostApp = NSWorkspace.shared.frontmostApplication,
           let appName = frontmostApp.localizedName {
            _ = await uiScanner.scanApplication(named: appName)
        }
    }
}

// MARK: - App

@main
struct OCRVisionApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowStyle(.automatic)
        .commands {
            CommandGroup(after: .appInfo) {
                Button("Preferences...") {
                    // Show preferences
                }
                .keyboardShortcut(",", modifiers: .command)
            }
        }
    }
}

import Vision
import AppKit
import Foundation
import CoreImage

// AXRole 기반 UI 요소 타입 매핑
func mapAXRoleToType(role: String) -> String {
    switch role {
    case "AXButton": return "button"
    case "AXTextField": return "input"
    case "AXTextArea": return "input"
    case "AXStaticText": return "label"
    case "AXCheckBox": return "checkbox"
    case "AXRadioButton": return "radio"
    case "AXMenu": return "menu"
    case "AXMenuButton": return "menu_button"
    case "AXScrollArea": return "scroll_area"
    case "AXToolbar": return "toolbar"
    case "AXImage": return "image"
    case "AXGroup": return "group"
    case "AXTable": return "table"
    case "AXRow": return "row"
    case "AXColumn": return "column"
    case "AXCell": return "cell"
    case "AXSlider": return "slider"
    case "AXProgressIndicator": return "progress"
    case "AXSplitGroup": return "split_group"
    case "AXTabGroup": return "tab_group"
    case "AXOutline": return "outline"
    case "AXDisclosureTriangle": return "disclosure"
    case "AXPopUpButton": return "popup_button"
    case "AXComboBox": return "combo_box"
    case "AXIncrementor": return "incrementor"
    case "AXRatingIndicator": return "rating"
    case "AXLevelIndicator": return "level"
    case "AXDockItem": return "dock_item"
    case "AXMatte": return "matte"
    case "AXLayoutItem": return "layout_item"
    case "AXHandle": return "handle"
    case "AXGrowArea": return "grow_area"
    case "AXSheet": return "sheet"
    case "AXDrawer": return "drawer"
    case "AXSystemWide": return "system_wide"
    case "AXApplication": return "application"
    case "AXWindow": return "window"
    default: return "unknown"
    }
}

// 위치 기반 매칭
func matchByPosition(ocrElement: [String: Any], uiElement: [String: Any], tolerance: Int = 50) -> Bool {
    guard let ocrX = ocrElement["x"] as? Int,
          let ocrY = ocrElement["y"] as? Int,
          let ocrW = ocrElement["width"] as? Int,
          let ocrH = ocrElement["height"] as? Int,
          let uiX = uiElement["x"] as? Int,
          let uiY = uiElement["y"] as? Int,
          let uiW = uiElement["width"] as? Int,
          let uiH = uiElement["height"] as? Int else {
        return false
    }

    // 중심점 계산
    let ocrCenterX = ocrX + ocrW / 2
    let ocrCenterY = ocrY + ocrH / 2
    let uiCenterX = uiX + uiW / 2
    let uiCenterY = uiY + uiH / 2

    // 중심점 거리 계산
    let distance = sqrt(pow(Double(ocrCenterX - uiCenterX), 2) + pow(Double(ocrCenterY - uiCenterY), 2))

    // 크기 비율 계산
    let widthRatio = min(Double(ocrW) / Double(uiW), Double(uiW) / Double(ocrW))
    let heightRatio = min(Double(ocrH) / Double(uiH), Double(uiH) / Double(ocrH))

    // 거리와 크기 비율 모두 고려
    return distance < Double(tolerance) && widthRatio > 0.5 && heightRatio > 0.5
}

// UI 결과 평탄화
func flattenUIResults(_ uiResults: [[String: Any]]) -> [[String: Any]] {
    var flattened: [[String: Any]] = []
    
    func traverse(_ element: [String: Any]) {
        // 위치 정보가 있는 요소만 추가
        if element["x"] != nil && element["y"] != nil && element["width"] != nil && element["height"] != nil {
            flattened.append(element)
        }
        
        // 자식 요소 재귀 처리
        if let children = element["children"] as? [[String: Any]] {
            for child in children {
                traverse(child)
            }
        }
    }
    
    for element in uiResults {
        traverse(element)
    }
    
    return flattened
}

// UI 스캔 결과 로드 (선택적)
func loadUIScanResults(for appName: String) -> [[String: Any]]? {
    let pid = getPID(for: appName)
    guard pid > 0 else { return nil }
    
    let appElement = AXUIElementCreateApplication(pid)
    var elements: [[String: Any]] = []
    
    func scanElement(_ element: AXUIElement, depth: Int, maxDepth: Int) {
        if depth > maxDepth { return }
        
        var roleValue: AnyObject?
        var titleValue: AnyObject?
        var valueAttr: AnyObject?
        var descValue: AnyObject?
        var posValue: AnyObject?
        var sizeValue: AnyObject?
        
        AXUIElementCopyAttributeValue(element, kAXRoleAttribute as CFString, &roleValue)
        AXUIElementCopyAttributeValue(element, kAXTitleAttribute as CFString, &titleValue)
        AXUIElementCopyAttributeValue(element, kAXValueAttribute as CFString, &valueAttr)
        AXUIElementCopyAttributeValue(element, kAXDescription as CFString, &descValue)
        AXUIElementCopyAttributeValue(element, kAXPositionAttribute as CFString, &posValue)
        AXUIElementCopyAttributeValue(element, kAXSizeAttribute as CFString, &sizeValue)
        
        let role = roleValue as? String ?? ""
        let title = titleValue as? String ?? ""
        let value = valueAttr as? String ?? (valueAttr as? NSNumber)?.stringValue ?? ""
        let desc = descValue as? String ?? ""
        
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
        if !desc.isEmpty { info["description"] = desc }
        
        elements.append(info)
        
        // 자식 요소 스캔
        var childrenValue: AnyObject?
        AXUIElementCopyAttributeValue(element, kAXChildrenAttribute as CFString, &childrenValue)
        if let childElements = childrenValue as? [AXUIElement] {
            for child in childElements {
                scanElement(child, depth: depth + 1, maxDepth: maxDepth)
            }
        }
    }
    
    var windowsValue: AnyObject?
    let err = AXUIElementCopyAttributeValue(appElement, kAXWindowsAttribute as CFString, &windowsValue)
    
    if err == .success, let windows = windowsValue as? [AXUIElement] {
        for window in windows {
            scanElement(window, depth: 0, maxDepth: 2)
        }
    }
    
    return elements
}

// PID 가져오기
func getPID(for appName: String) -> pid_t {
    let apps = NSWorkspace.shared.runningApplications
    if let app = apps.first(where: { $0.localizedName?.contains(appName) ?? false || $0.bundleIdentifier?.contains(appName) ?? false }) {
        return app.processIdentifier
    }
    return 0
}

// 색상 분류
func classifyColor(r: Int, g: Int, b: Int) -> String {
    // 버튼 색상
    if abs(r - 0) < 10 && abs(g - 122) < 10 && abs(b - 255) < 10 {
        return "button_blue"
    }
    if abs(r - 52) < 10 && abs(g - 199) < 10 && abs(b - 89) < 10 {
        return "button_green"
    }
    if abs(r - 142) < 10 && abs(g - 142) < 10 && abs(b - 147) < 10 {
        return "button_gray"
    }
    
    // 입력창 색상
    if r >= 240 && g >= 240 && b >= 240 {
        return "input_field"
    }
    
    // 경고 색상
    if abs(r - 255) < 10 && abs(g - 59) < 10 && abs(b - 48) < 10 {
        return "warning_red"
    }
    if abs(r - 255) < 10 && abs(g - 204) < 10 && abs(b - 0) < 10 {
        return "warning_yellow"
    }
    
    return "unknown"
}

// 텍스트가 사각형 안에 있는지 확인
func isTextInRectangle(text: [String: Any], rect: [String: Any]) -> Bool {
    guard let textX = text["x"] as? Int,
          let textY = text["y"] as? Int,
          let textW = text["width"] as? Int,
          let textH = text["height"] as? Int,
          let rectX = rect["x"] as? Int,
          let rectY = rect["y"] as? Int,
          let rectW = rect["width"] as? Int,
          let rectH = rect["height"] as? Int else {
        return false
    }
    
    return textX >= rectX && 
           textY >= rectY && 
           textX + textW <= rectX + rectW && 
           textY + textH <= rectY + rectH
}

// UI 요소 패턴 분석
func analyzeUIPatterns(texts: [[String: Any]], rects: [[String: Any]], color: [String: Any]) -> [[String: Any]] {
    var uiElements: [[String: Any]] = []
    
    for rect in rects {
        var element = rect
        let r = color["r"] as! Int
        let g = color["g"] as! Int
        let b = color["b"] as! Int
        let colorType = classifyColor(r: r, g: g, b: b)
        element["color_type"] = colorType
        
        // 텍스트 매칭
        for text in texts {
            if isTextInRectangle(text: text, rect: rect) {
                element["text"] = text["text"]
                break
            }
        }
        
        uiElements.append(element)
    }
    
    return uiElements
}

// 메인
let imagePath = CommandLine.arguments[1]
let appName = CommandLine.arguments.count > 2 ? CommandLine.arguments[2] : ""

guard let image = NSImage(contentsOfFile: imagePath),
      let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
    print("ERROR: Cannot load image")
    exit(1)
}

let imageWidth = cgImage.width
let imageHeight = cgImage.height
var allResults: [String: Any] = [:]
let semaphore = DispatchSemaphore(value: 0)

// 1. Text OCR with bounding boxes
let textRequest = VNRecognizeTextRequest { request, error in
    guard let observations = request.results as? [VNRecognizedTextObservation] else { return }
    var texts: [[String: Any]] = []
    for obs in observations {
        guard let candidate = obs.topCandidates(1).first else { continue }
        let bbox = obs.boundingBox
        texts.append([
            "text": candidate.string,
            "confidence": String(format: "%.2f", candidate.confidence),
            "x": Int(bbox.origin.x * CGFloat(imageWidth)),
            "y": Int((1 - bbox.origin.y - bbox.height) * CGFloat(imageHeight)),
            "width": Int(bbox.width * CGFloat(imageWidth)),
            "height": Int(bbox.height * CGFloat(imageHeight))
        ])
    }
    allResults["texts"] = texts
    semaphore.signal()
}
textRequest.recognitionLevel = VNRequestTextRecognitionLevel.accurate
textRequest.recognitionLanguages = ["ko-KR", "en-US"]
textRequest.usesLanguageCorrection = true

// 2. Rectangle detection
let rectRequest = VNDetectRectanglesRequest { request, error in
    guard let observations = request.results as? [VNRectangleObservation] else { return }
    var rects: [[String: Any]] = []
    for obs in observations {
        let bbox = obs.boundingBox
        rects.append([
            "x": Int(bbox.origin.x * CGFloat(imageWidth)),
            "y": Int((1 - bbox.origin.y - bbox.height) * CGFloat(imageHeight)),
            "width": Int(bbox.width * CGFloat(imageWidth)),
            "height": Int(bbox.height * CGFloat(imageHeight)),
            "confidence": String(format: "%.2f", obs.confidence)
        ])
    }
    allResults["rectangles"] = rects
    semaphore.signal()
}
rectRequest.minimumConfidence = 0.3
rectRequest.maximumObservations = 50
rectRequest.minimumAspectRatio = 0.5
rectRequest.maximumAspectRatio = 3.0
rectRequest.minimumSize = 0.01
rectRequest.quadratureTolerance = 0.2

// 3. Barcode/QR detection
let barcodeRequest = VNDetectBarcodesRequest { request, error in
    guard let observations = request.results as? [VNBarcodeObservation] else { return }
    var barcodes: [[String: Any]] = []
    for obs in observations {
        let bbox = obs.boundingBox
        barcodes.append([
            "type": obs.symbology.rawValue,
            "value": obs.payloadStringValue ?? "",
            "x": Int(bbox.origin.x * CGFloat(imageWidth)),
            "y": Int((1 - bbox.origin.y - bbox.height) * CGFloat(imageHeight)),
            "width": Int(bbox.width * CGFloat(imageWidth)),
            "height": Int(bbox.height * CGFloat(imageHeight))
        ])
    }
    allResults["barcodes"] = barcodes
    semaphore.signal()
}

// 4. Image classification (scene labels)
let classifyRequest = VNClassifyImageRequest { request, error in
    guard let observations = request.results as? [VNClassificationObservation] else { return }
    var labels: [[String: Any]] = []
    for obs in observations.prefix(10) {
        if obs.confidence > 0.1 {
            labels.append(["label": obs.identifier, "confidence": String(format: "%.2f", obs.confidence)])
        }
    }
    allResults["labels"] = labels
    semaphore.signal()
}

// 5. Detect colors - sample dominant colors
let ciImage = CIImage(cgImage: cgImage)
let context = CIContext()
if let filter = CIFilter(name: "CIAreaAverage", parameters: ["inputImage": ciImage, "inputExtent": CIVector(x: 0, y: 0, z: CGFloat(imageWidth), w: CGFloat(imageHeight))]),
   let outputImage = filter.outputImage,
   let cgOutput = context.createCGImage(outputImage, from: CGRect(x: 0, y: 0, width: 1, height: 1)) {
    let pixelData = cgOutput.dataProvider!.data
    let data = CFDataGetBytePtr(pixelData)!
    let r = Int(data[0]), g = Int(data[1]), b = Int(data[2])
    allResults["dominant_color"] = ["r": r, "g": g, "b": b, "hex": String(format: "#%02X%02X%02X", r, g, b)]
}

// Execute all requests
let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
try? handler.perform([textRequest, rectRequest, barcodeRequest, classifyRequest])

allResults["dimensions"] = ["width": imageWidth, "height": imageHeight]

// UI 요소 패턴 분석 추가
if let texts = allResults["texts"] as? [[String: Any]],
   let rects = allResults["rectangles"] as? [[String: Any]],
   let color = allResults["dominant_color"] as? [String: Any] {
    let uiElements = analyzeUIPatterns(texts: texts, rects: rects, color: color)
    allResults["ui_elements"] = uiElements
}

// UI 스캔 결과 통합 (앱 이름이 제공된 경우)
if !appName.isEmpty {
    if let uiResults = loadUIScanResults(for: appName) {
        let flattenedUIResults = flattenUIResults(uiResults)
        
        // UI 요소에 AXRole 정보 추가
        if var uiElements = allResults["ui_elements"] as? [[String: Any]] {
            var enhancedUIElements: [[String: Any]] = []
            
            for uiElement in uiElements {
                var enhancedElement = uiElement
                
                for uiResult in flattenedUIResults {
                    if matchByPosition(ocrElement: uiElement, uiElement: uiResult) {
                        if let role = uiResult["role"] as? String {
                            enhancedElement["ax_role"] = role
                            enhancedElement["ui_type"] = mapAXRoleToType(role: role)
                        }
                        if let title = uiResult["title"] as? String, !title.isEmpty {
                            enhancedElement["title"] = title
                        }
                        if let value = uiResult["value"] as? String, !value.isEmpty {
                            enhancedElement["value"] = value
                        }
                        if let description = uiResult["description"] as? String, !description.isEmpty {
                            enhancedElement["description"] = description
                        }
                        break
                    }
                }
                
                enhancedUIElements.append(enhancedElement)
            }
            
            allResults["ui_elements"] = enhancedUIElements
        }
        
        // 텍스트에 AXRole 정보 추가
        if var texts = allResults["texts"] as? [[String: Any]] {
            var enhancedTexts: [[String: Any]] = []
            
            for text in texts {
                var enhancedText = text
                
                for uiResult in flattenedUIResults {
                    if matchByPosition(ocrElement: text, uiElement: uiResult) {
                        if let role = uiResult["role"] as? String {
                            enhancedText["ax_role"] = role
                            enhancedText["ui_type"] = mapAXRoleToType(role: role)
                        }
                        break
                    }
                }
                
                enhancedTexts.append(enhancedText)
            }
            
            allResults["texts"] = enhancedTexts
        }
        
        // 통합 통계 추가
        if let uiElements = allResults["ui_elements"] as? [[String: Any]],
           let texts = allResults["texts"] as? [[String: Any]] {
            let totalUIElements = uiElements.count
            let elementsWithAXRole = uiElements.filter { $0["ax_role"] != nil }.count
            let totalTexts = texts.count
            let textsWithAXRole = texts.filter { $0["ax_role"] != nil }.count
            
            allResults["merge_stats"] = [
                "total_ui_elements": totalUIElements,
                "ui_elements_with_ax_role": elementsWithAXRole,
                "ui_elements_ax_role_coverage": String(format: "%.1f%%", Double(elementsWithAXRole) / Double(totalUIElements) * 100),
                "total_texts": totalTexts,
                "texts_with_ax_role": textsWithAXRole,
                "texts_ax_role_coverage": String(format: "%.1f%%", Double(textsWithAXRole) / Double(totalTexts) * 100)
            ]
        }
    }
}

if let jsonData = try? JSONSerialization.data(withJSONObject: allResults, options: [.prettyPrinted, .sortedKeys]),
   let jsonString = String(data: jsonData, encoding: .utf8) {
    print(jsonString)
}
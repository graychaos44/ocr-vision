import Vision
import AppKit
import Foundation
import CoreImage

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
    if r >= 240 && g >= 240 && b >= 240 {
        return "input_field_gray"
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
    let textX = text["x"] as! Int
    let textY = text["y"] as! Int
    let textW = text["width"] as! Int
    let textH = text["height"] as! Int
    
    let rectX = rect["x"] as! Int
    let rectY = rect["y"] as! Int
    let rectW = rect["width"] as! Int
    let rectH = rect["height"] as! Int
    
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

// AXRole 기반 UI 요소 타입 매핑
func mapAXRoleToType(role: String) -> String {
    switch role {
    case "AXButton": return "button"
    case "AXTextField": return "input"
    case "AXStaticText": return "label"
    case "AXCheckBox": return "checkbox"
    case "AXRadioButton": return "radio"
    case "AXMenu": return "menu"
    default: return "unknown"
    }
}

// 위치 기반 매칭
func matchByPosition(ocrElement: [String: Any], uiElement: [String: Any]) -> Bool {
    let ocrX = ocrElement["x"] as! Int
    let ocrY = ocrElement["y"] as! Int
    let uiX = uiElement["x"] as! Int
    let uiY = uiElement["y"] as! Int
    
    let distance = sqrt(pow(Double(ocrX - uiX), 2) + pow(Double(ocrY - uiY), 2))
    return distance < 50 // 50픽셀 이내면 매칭
}

let imagePath = CommandLine.arguments[1]
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

if let jsonData = try? JSONSerialization.data(withJSONObject: allResults, options: [.prettyPrinted, .sortedKeys]),
   let jsonString = String(data: jsonData, encoding: .utf8) {
    print(jsonString)
}
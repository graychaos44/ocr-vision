import Vision
import AppKit
import Foundation
import CoreImage

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

if let jsonData = try? JSONSerialization.data(withJSONObject: allResults, options: [.prettyPrinted, .sortedKeys]),
   let jsonString = String(data: jsonData, encoding: .utf8) {
    print(jsonString)
}
import Foundation

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

// 위치 기반 매칭 (개선된 버전)
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

// 영역 중첩 확인
func hasOverlap(element1: [String: Any], element2: [String: Any]) -> Bool {
    guard let x1 = element1["x"] as? Int,
          let y1 = element1["y"] as? Int,
          let w1 = element1["width"] as? Int,
          let h1 = element1["height"] as? Int,
          let x2 = element2["x"] as? Int,
          let y2 = element2["y"] as? Int,
          let w2 = element2["width"] as? Int,
          let h2 = element2["height"] as? Int else {
        return false
    }

    let overlapX = max(0, min(x1 + w1, x2 + w2) - max(x1, x2))
    let overlapY = max(0, min(y1 + h1, y2 + h2) - max(y1, y2))
    let overlapArea = overlapX * overlapY

    let area1 = w1 * h1
    let area2 = w2 * h2
    let minArea = min(area1, area2)

    // 중첩 영역이 더 작은 요소의 50% 이상이면 중첩으로 간주
    return overlapArea > minArea / 2
}

// UI 결과 평탄화 (중첩 구조를 단일 레벨로 변환)
func flattenUIResults(_ uiResults: [[String: Any]]) -> [[String: Any]] {
    var flattened: [[String: Any]] = []
    
    func traverse(_ element: [String: Any]) {
        // 위치 정보가 있는 요소만 추가
        if let x = element["x"] as? Int,
           let y = element["y"] as? Int,
           let w = element["width"] as? Int,
           let h = element["height"] as? Int {
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

// OCR 결과와 UI 스캔 결과 통합
func mergeOCRAndUI(ocrResults: [String: Any], uiResults: [[String: Any]]) -> [String: Any] {
    var mergedResults = ocrResults

    guard let texts = ocrResults["texts"] as? [[String: Any]],
          let uiElements = ocrResults["ui_elements"] as? [[String: Any]] else {
        return mergedResults
    }

    // UI 결과 평탄화
    let flattenedUIResults = flattenUIResults(uiResults)

    // UI 요소에 AXRole 정보 추가
    var enhancedUIElements: [[String: Any]] = []

    for uiElement in uiElements {
        var enhancedElement = uiElement

        // UI 스캔 결과에서 매칭되는 요소 찾기
        for uiResult in flattenedUIResults {
            if matchByPosition(ocrElement: uiElement, uiElement: uiResult) {
                // AXRole 정보 추가
                if let role = uiResult["role"] as? String {
                    enhancedElement["ax_role"] = role
                    enhancedElement["ui_type"] = mapAXRoleToType(role: role)
                }

                // 추가 정보 병합
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

    // 텍스트에 AXRole 정보 추가
    var enhancedTexts: [[String: Any]] = []

    for text in texts {
        var enhancedText = text

        // UI 스캔 결과에서 매칭되는 요소 찾기
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

    mergedResults["ui_elements"] = enhancedUIElements
    mergedResults["texts"] = enhancedTexts

    // 통합 통계 추가
    let totalUIElements = enhancedUIElements.count
    let elementsWithAXRole = enhancedUIElements.filter { $0["ax_role"] != nil }.count
    let totalTexts = enhancedTexts.count
    let textsWithAXRole = enhancedTexts.filter { $0["ax_role"] != nil }.count

    mergedResults["merge_stats"] = [
        "total_ui_elements": totalUIElements,
        "ui_elements_with_ax_role": elementsWithAXRole,
        "ui_elements_ax_role_coverage": String(format: "%.1f%%", Double(elementsWithAXRole) / Double(totalUIElements) * 100),
        "total_texts": totalTexts,
        "texts_with_ax_role": textsWithAXRole,
        "texts_ax_role_coverage": String(format: "%.1f%%", Double(textsWithAXRole) / Double(totalTexts) * 100)
    ]

    return mergedResults
}

// 메인 함수
if CommandLine.arguments.count < 3 {
    print("Usage: merge_results <ocr_json_file> <ui_json_file>")
    exit(1)
}

let ocrJSONPath = CommandLine.arguments[1]
let uiJSONPath = CommandLine.arguments[2]

// OCR 결과 로드
guard let ocrData = try? Data(contentsOf: URL(fileURLWithPath: ocrJSONPath)),
      let ocrResults = try? JSONSerialization.jsonObject(with: ocrData) as? [String: Any] else {
    print("ERROR: Cannot load OCR results from \(ocrJSONPath)")
    exit(1)
}

// UI 스캔 결과 로드
guard let uiData = try? Data(contentsOf: URL(fileURLWithPath: uiJSONPath)),
      let uiResults = try? JSONSerialization.jsonObject(with: uiData) as? [[String: Any]] else {
    print("ERROR: Cannot load UI scan results from \(uiJSONPath)")
    exit(1)
}

// 결과 통합
let mergedResults = mergeOCRAndUI(ocrResults: ocrResults, uiResults: uiResults)

// JSON 출력
if let jsonData = try? JSONSerialization.data(withJSONObject: mergedResults, options: [.prettyPrinted, .sortedKeys]),
   let jsonString = String(data: jsonData, encoding: .utf8) {
    print(jsonString)
}
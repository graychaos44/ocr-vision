import Foundation

// 정확도 테스트
struct TestCase {
    let name: String
    let ocrFile: String
    let uiFile: String
    let expectedUIElements: Int
    let expectedTexts: Int
    let expectedMatchRate: Double
}

let testCases: [TestCase] = [
    TestCase(
        name: "기본 로그인 폼",
        ocrFile: "/Users/gray/scripts/vision-tools/test_ocr.json",
        uiFile: "/Users/gray/scripts/vision-tools/test_ui.json",
        expectedUIElements: 4,
        expectedTexts: 4,
        expectedMatchRate: 1.0
    )
]

func runAccuracyTest(_ testCase: TestCase) -> [String: Any] {
    print("테스트: \(testCase.name)")
    
    // 결과 통합
    let task = Process()
    task.executableURL = URL(fileURLWithPath: "/Users/gray/scripts/vision-tools/merge_results")
    task.arguments = [testCase.ocrFile, testCase.uiFile]
    
    let pipe = Pipe()
    task.standardOutput = pipe
    task.standardError = pipe
    
    var result: [String: Any] = [:]
    
    do {
        try task.run()
        task.waitUntilExit()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            result = json
        }
    } catch {
        print("ERROR: \(error)")
        return ["error": error.localizedDescription]
    }
    
    // 통계 추출
    let mergeStats = result["merge_stats"] as? [String: Any] ?? [:]
    let totalUIElements = mergeStats["total_ui_elements"] as? Int ?? 0
    let uiElementsWithAXRole = mergeStats["ui_elements_with_ax_role"] as? Int ?? 0
    let totalTexts = mergeStats["total_texts"] as? Int ?? 0
    let textsWithAXRole = mergeStats["texts_with_ax_role"] as? Int ?? 0
    
    // 정확도 계산
    let uiElementAccuracy = totalUIElements > 0 ? Double(uiElementsWithAXRole) / Double(totalUIElements) : 0
    let textAccuracy = totalTexts > 0 ? Double(textsWithAXRole) / Double(totalTexts) : 0
    let overallAccuracy = (uiElementAccuracy + textAccuracy) / 2
    
    // 결과 비교
    let uiElementMatch = totalUIElements == testCase.expectedUIElements
    let textMatch = totalTexts == testCase.expectedTexts
    let matchRateMatch = abs(overallAccuracy - testCase.expectedMatchRate) < 0.1
    
    let passed = uiElementMatch && textMatch && matchRateMatch
    
    return [
        "test_name": testCase.name,
        "passed": passed,
        "ui_elements": [
            "expected": testCase.expectedUIElements,
            "actual": totalUIElements,
            "match": uiElementMatch
        ],
        "texts": [
            "expected": testCase.expectedTexts,
            "actual": totalTexts,
            "match": textMatch
        ],
        "accuracy": [
            "expected": String(format: "%.1f%%", testCase.expectedMatchRate * 100),
            "actual": String(format: "%.1f%%", overallAccuracy * 100),
            "match": matchRateMatch
        ],
        "merge_stats": mergeStats
    ]
}

// 메인
print("=== OCR Vision Tools 정확도 테스트 ===\n")

var passedCount = 0
var failedCount = 0

for testCase in testCases {
    let result = runAccuracyTest(testCase)
    
    if let passed = result["passed"] as? Bool, passed {
        passedCount += 1
        print("✅ PASSED")
    } else {
        failedCount += 1
        print("❌ FAILED")
    }
    
    print("   UI 요소: \(result["ui_elements"] ?? [:])")
    print("   텍스트: \(result["texts"] ?? [:])")
    print("   정확도: \(result["accuracy"] ?? [:])")
    print()
}

print("=== 테스트 결과 ===")
print("통과: \(passedCount)")
print("실패: \(failedCount)")
print("성공률: \(String(format: "%.1f%%", Double(passedCount) / Double(testCases.count) * 100))")
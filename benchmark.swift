import Foundation

// 성능 벤치마킹
func benchmarkOCR(imagePath: String, iterations: Int = 10) -> [String: Any] {
    var times: [Double] = []
    
    for _ in 0..<iterations {
        let start = Date()
        
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/Users/gray/scripts/vision-tools/ocr_vision")
        task.arguments = [imagePath]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe
        
        do {
            try task.run()
            task.waitUntilExit()
            
            let end = Date()
            let elapsed = end.timeIntervalSince(start)
            times.append(elapsed)
        } catch {
            print("ERROR: \(error)")
        }
    }
    
    let avgTime = times.reduce(0, +) / Double(times.count)
    let minTime = times.min() ?? 0
    let maxTime = times.max() ?? 0
    
    return [
        "iterations": iterations,
        "avg_time": String(format: "%.3f", avgTime),
        "min_time": String(format: "%.3f", minTime),
        "max_time": String(format: "%.3f", maxTime),
        "times": times
    ]
}

func benchmarkUIScan(appName: String, iterations: Int = 10) -> [String: Any] {
    var times: [Double] = []
    
    for _ in 0..<iterations {
        let start = Date()
        
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/Users/gray/scripts/vision-tools/ui_scan")
        task.arguments = [appName]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe
        
        do {
            try task.run()
            task.waitUntilExit()
            
            let end = Date()
            let elapsed = end.timeIntervalSince(start)
            times.append(elapsed)
        } catch {
            print("ERROR: \(error)")
        }
    }
    
    let avgTime = times.reduce(0, +) / Double(times.count)
    let minTime = times.min() ?? 0
    let maxTime = times.max() ?? 0
    
    return [
        "iterations": iterations,
        "avg_time": String(format: "%.3f", avgTime),
        "min_time": String(format: "%.3f", minTime),
        "max_time": String(format: "%.3f", maxTime),
        "times": times
    ]
}

func benchmarkMerge(ocrPath: String, uiPath: String, iterations: Int = 10) -> [String: Any] {
    var times: [Double] = []
    
    for _ in 0..<iterations {
        let start = Date()
        
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/Users/gray/scripts/vision-tools/merge_results")
        task.arguments = [ocrPath, uiPath]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe
        
        do {
            try task.run()
            task.waitUntilExit()
            
            let end = Date()
            let elapsed = end.timeIntervalSince(start)
            times.append(elapsed)
        } catch {
            print("ERROR: \(error)")
        }
    }
    
    let avgTime = times.reduce(0, +) / Double(times.count)
    let minTime = times.min() ?? 0
    let maxTime = times.max() ?? 0
    
    return [
        "iterations": iterations,
        "avg_time": String(format: "%.3f", avgTime),
        "min_time": String(format: "%.3f", minTime),
        "max_time": String(format: "%.3f", maxTime),
        "times": times
    ]
}

// 메인
print("=== OCR Vision Tools 성능 벤치마킹 ===\n")

// OCR 벤치마킹
print("1. ocr_vision 벤치마킹...")
let ocrBenchmark = benchmarkOCR(imagePath: "/Users/gray/scripts/vision-tools/test_ocr.json", iterations: 10)
print("   - 반복 횟수: \(ocrBenchmark["iterations"] ?? 0)")
print("   - 평균 시간: \(ocrBenchmark["avg_time"] ?? "N/A")초")
print("   - 최소 시간: \(ocrBenchmark["min_time"] ?? "N/A")초")
print("   - 최대 시간: \(ocrBenchmark["max_time"] ?? "N/A")초")
print()

// UI 스캔 벤치마킹
print("2. ui_scan 벤치마킹...")
let uiBenchmark = benchmarkUIScan(appName: "Finder", iterations: 10)
print("   - 반복 횟수: \(uiBenchmark["iterations"] ?? 0)")
print("   - 평균 시간: \(uiBenchmark["avg_time"] ?? "N/A")초")
print("   - 최소 시간: \(uiBenchmark["min_time"] ?? "N/A")초")
print("   - 최대 시간: \(uiBenchmark["max_time"] ?? "N/A")초")
print()

// 통합 벤치마킹
print("3. merge_results 벤치마킹...")
let mergeBenchmark = benchmarkMerge(
    ocrPath: "/Users/gray/scripts/vision-tools/test_ocr.json",
    uiPath: "/Users/gray/scripts/vision-tools/test_ui.json",
    iterations: 10
)
print("   - 반복 횟수: \(mergeBenchmark["iterations"] ?? 0)")
print("   - 평균 시간: \(mergeBenchmark["avg_time"] ?? "N/A")초")
print("   - 최소 시간: \(mergeBenchmark["min_time"] ?? "N/A")초")
print("   - 최대 시간: \(mergeBenchmark["max_time"] ?? "N/A")초")
print()

// 전체 파이프라인
print("4. 전체 파이프라인 (OCR + UI 스캔 + 통합)...")
let ocrAvg = (ocrBenchmark["avg_time"] as? String ?? "0").toDouble() ?? 0
let uiAvg = (uiBenchmark["avg_time"] as? String ?? "0").toDouble() ?? 0
let mergeAvg = (mergeBenchmark["avg_time"] as? String ?? "0").toDouble() ?? 0
let totalAvgTime = ocrAvg + uiAvg + mergeAvg
print("   - 전체 평균 시간: \(String(format: "%.3f", totalAvgTime))초")
print()

print("=== 벤치마킹 완료 ===")

extension String {
    func toDouble() -> Double? {
        return Double(self.replacingOccurrences(of: "초", with: ""))
    }
}
import ApplicationServices
import Foundation
import AppKit

func scanAppByPID(_ pid: pid_t) -> [[String: Any]] {
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

func getElementInfo(_ element: AXUIElement, depth: Int, maxDepth: Int) -> [String: Any] {
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

// Main
if CommandLine.arguments.count < 2 {
    print("Usage: ui_scan <app_name_or_pid>")
    print("Example: ui_scan Finder")
    print("         ui_scan 1234")
    exit(1)
}

let target = CommandLine.arguments[1]

// Find app by name or PID
var pid: pid_t = 0
if let pidNum = Int(target) {
    pid = pid_t(pidNum)
} else {
    let apps = NSWorkspace.shared.runningApplications
    if let app = apps.first(where: { $0.localizedName?.contains(target) ?? false || $0.bundleIdentifier?.contains(target) ?? false }) {
        pid = app.processIdentifier
    }
}

if pid == 0 {
    print("[]")
    exit(1)
}

let results = scanAppByPID(pid)
if let jsonData = try? JSONSerialization.data(withJSONObject: results, options: [.prettyPrinted, .sortedKeys]),
   let jsonString = String(data: jsonData, encoding: .utf8) {
    print(jsonString)
}
// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "OCRVisionApp",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "OCRVisionApp", targets: ["OCRVisionApp"]),
    ],
    targets: [
        .executableTarget(
            name: "OCRVisionApp",
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
    ]
)

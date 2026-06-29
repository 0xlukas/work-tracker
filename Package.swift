// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "WorkTracker",
    defaultLocalization: "en",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "WorkTracker",
            path: "WorkTracker/Sources",
            resources: [
                .process("Resources")
            ]
        )
    ]
)

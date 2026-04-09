// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "WorkTracker",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "WorkTracker",
            path: "WorkTracker/Sources"
        )
    ]
)

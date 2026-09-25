// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "WorkTracker",
    defaultLocalization: "en",
    // macOS 27 only — the UI targets the current Liquid Glass design language and
    // makes no attempt at backwards compatibility.
    platforms: [.macOS("27.0")],
    targets: [
        .executableTarget(
            name: "WorkTracker",
            path: "WorkTracker/Sources",
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(name: "WorkTrackerTests", dependencies: ["WorkTracker"])
    ]
)

// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Deskmates",
    platforms: [.macOS(.v14)],
    targets: [
        // Everything lives here, so a test can reach it. An executable target
        // cannot be imported.
        .target(
            name: "DeskmatesCore",
            path: "Sources/DeskmatesCore",
            resources: [.copy("Resources")]
        ),
        .executableTarget(
            name: "Deskmates",
            dependencies: ["DeskmatesCore"],
            path: "Sources/Deskmates"
        ),
        // Checks run as a program, not as `swift test`. XCTest and
        // swift-testing both ship with Xcode, and this machine has only the
        // Command Line Tools.
        .executableTarget(
            name: "Checks",
            dependencies: ["DeskmatesCore"],
            path: "Sources/Checks"
        ),
    ]
)

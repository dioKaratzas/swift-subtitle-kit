// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "swift-subtitle-kit",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15),
        .tvOS(.v13),
        .watchOS(.v6),
    ],
    products: [
        .library(
            name: "SubtitleKit",
            targets: ["SubtitleKit"]
        )
    ],
    targets: [
        .target(
            name: "SubtitleKit"
        ),
        .testTarget(
            name: "SubtitleKitTests",
            dependencies: ["SubtitleKit"],
            resources: [
                .copy("Fixtures")
            ]
        )
    ]
)

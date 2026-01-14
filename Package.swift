// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "SubtitleKit",
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

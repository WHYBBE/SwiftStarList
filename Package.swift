// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "StarList",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "StarList", targets: ["StarList"]),
    ],
    dependencies: [
        .package(url: "https://github.com/gonzalezreal/swift-markdown-ui", from: "2.2.0"),
    ],
    targets: [
        .executableTarget(
            name: "StarList",
            dependencies: [
                .product(name: "MarkdownUI", package: "swift-markdown-ui"),
            ],
            path: "StarList",
            exclude: ["StarList.entitlements"]
        ),
    ]
)

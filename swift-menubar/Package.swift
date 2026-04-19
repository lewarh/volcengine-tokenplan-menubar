// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "CodingPlanMenuBar",
    platforms: [
        .macOS(.v13),
    ],
    products: [
        .library(name: "CodingPlanKit", targets: ["CodingPlanKit"]),
        .executable(name: "CodingPlanMenuBar", targets: ["CodingPlanMenuBar"]),
    ],
    targets: [
        .target(name: "CodingPlanKit"),
        .executableTarget(
            name: "CodingPlanMenuBar",
            dependencies: ["CodingPlanKit"]
        ),
        .testTarget(
            name: "CodingPlanKitTests",
            dependencies: ["CodingPlanKit"]
        ),
    ]
)

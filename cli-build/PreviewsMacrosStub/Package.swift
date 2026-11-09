// swift-tools-version:6.0
import PackageDescription
let package = Package(
  name: "PreviewsMacrosStub",
  platforms: [.macOS(.v13)],
  dependencies: [ .package(path: "/Volumes/SandiskSSD/notch-build/.build/checkouts/swift-syntax") ],
  targets: [ .executableTarget(name: "PreviewsMacros", dependencies: [
    .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
    .product(name: "SwiftSyntaxMacros", package: "swift-syntax")]) ]
)

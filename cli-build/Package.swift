// swift-tools-version:6.0
// CLI-BUILD: builds Atoll without Xcode. Not part of upstream.
import PackageDescription

let package = Package(
    name: "AtollCLI",
    platforms: [.macOS("14.6")],
    products: [.executable(name: "Atoll", targets: ["Atoll"])],
    dependencies: [
        .package(url: "https://github.com/TheBoredTeam/MacroVisionKit", exact: "0.1.0"),
        .package(url: "https://github.com/sindresorhus/LaunchAtLogin-Modern", branch: "main"),
        .package(path: "/Volumes/SandiskSSD/notch-build/local/Sparkle"),
        .package(url: "https://github.com/Ebullioscopic/AtollExtensionKit", branch: "main"),
        .package(url: "https://github.com/Lakr233/SkyLightWindow", branch: "main"),
        .package(url: "https://github.com/migueldeicaza/SwiftTerm", exact: "1.13.0"),
        .package(url: "https://github.com/siteline/swiftui-introspect", exact: "1.3.0"),
        .package(url: "https://github.com/sindresorhus/KeyboardShortcuts", exact: "2.3.0"),
        .package(url: "https://github.com/sindresorhus/Defaults", exact: "9.0.3"),
        .package(url: "https://github.com/jasudev/LottieUI.git", branch: "main"),
        .package(path: "/Volumes/SandiskSSD/notch-build/local/lottie-spm"),
        .package(url: "https://github.com/apple/swift-collections.git", exact: "1.1.4"),
    ],
    targets: [
        .target(
            name: "AudioBridge",
            path: "Sources/AudioBridge",
            cxxSettings: [.unsafeFlags(["-std=c++17"])],
            linkerSettings: [.linkedFramework("Accelerate")]
        ),
        .executableTarget(
            name: "Atoll",
            dependencies: [
                "AudioBridge",
                .product(name: "MacroVisionKit", package: "MacroVisionKit"),
                .product(name: "LaunchAtLogin", package: "LaunchAtLogin-Modern"),
                .product(name: "Sparkle", package: "Sparkle"),
                .product(name: "AtollExtensionKit", package: "AtollExtensionKit"),
                .product(name: "SkyLightWindow", package: "SkyLightWindow"),
                .product(name: "SwiftTerm", package: "SwiftTerm"),
                .product(name: "SwiftUIIntrospect", package: "swiftui-introspect"),
                .product(name: "KeyboardShortcuts", package: "KeyboardShortcuts"),
                .product(name: "Defaults", package: "Defaults"),
                .product(name: "LottieUI", package: "LottieUI"),
                .product(name: "Lottie", package: "lottie-spm"),
                .product(name: "Collections", package: "swift-collections"),
            ],
            path: "Sources/Atoll",
            exclude: [
                "audio/AudioBridge.h", "audio/AudioBridge.mm", "audio/AudioProcessor.cpp", "audio/AudioProcessor.hpp", "metal", "Assets.xcassets", "Preview Content", "BluetoothHUDAnimations",
                "Localizable.xcstrings", "tr.lproj", "Info.plist", "DynamicIsland.entitlements",
                "DynamicIsland-Bridging-Header.h", "managers/LLMUsage/pricing.json",
                "audio-feedback.m4a", "dynamic.m4a", "lock.mp3", "lowbattery.mp3", "timer.mp3", "unlock.mp3",
            ],
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
    ]
)

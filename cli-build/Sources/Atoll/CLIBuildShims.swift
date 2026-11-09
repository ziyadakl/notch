// CLI-BUILD: shims so macOS 26 SDK APIs compile against the 15.5 SDK (Command Line Tools only).
// Compiled out entirely when building with a Swift 6.2+ toolchain (Xcode 26).
#if !compiler(>=6.2)
import SwiftUI

struct Glass {
    static var regular: Glass { Glass() }
    static var clear: Glass { Glass() }
    func tint(_ color: Color?) -> Glass { self }
    func interactive(_ isEnabled: Bool = true) -> Glass { self }
}

extension View {
    func glassEffect<S: Shape>(_ glass: Glass = .regular, in shape: S) -> some View { self }
}

extension ToolbarContent {
    func sharedBackgroundVisibility(_ visibility: Visibility) -> some ToolbarContent { self }
}

// Asset-catalog symbol (actool is unavailable); loose PNGs are used instead where possible.
extension ImageResource {
    static let github = ImageResource(name: "github", bundle: .main)
}
#endif

// CLI-BUILD: stand-in for Xcode's PreviewsMacros plugin; expands #Preview to nothing.
import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxMacros

struct SwiftUIView: DeclarationMacro {
    static func expansion(of node: some FreestandingMacroExpansionSyntax, in context: some MacroExpansionContext) throws -> [DeclSyntax] { [] }
}
struct AppKitView: DeclarationMacro {
    static func expansion(of node: some FreestandingMacroExpansionSyntax, in context: some MacroExpansionContext) throws -> [DeclSyntax] { [] }
}
struct AppKitViewController: DeclarationMacro {
    static func expansion(of node: some FreestandingMacroExpansionSyntax, in context: some MacroExpansionContext) throws -> [DeclSyntax] { [] }
}
struct UIKitView: DeclarationMacro {
    static func expansion(of node: some FreestandingMacroExpansionSyntax, in context: some MacroExpansionContext) throws -> [DeclSyntax] { [] }
}
struct UIKitViewController: DeclarationMacro {
    static func expansion(of node: some FreestandingMacroExpansionSyntax, in context: some MacroExpansionContext) throws -> [DeclSyntax] { [] }
}
@main struct PreviewsPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [SwiftUIView.self, AppKitView.self, AppKitViewController.self, UIKitView.self, UIKitViewController.self]
}

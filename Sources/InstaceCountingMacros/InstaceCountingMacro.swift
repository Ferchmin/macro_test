import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import Foundation

/// Implementation of the `stringify` macro, which takes an expression
/// of any type and produces a tuple containing the value of that expression
/// and the source code that produced the value. For example
///
///     #stringify(x + y)
///
///  will expand to
///
///     (x + y, "x + y")
public struct StringifyMacro: ExpressionMacro {
    public static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) -> ExprSyntax {
        guard let argument = node.arguments.first?.expression else {
            fatalError("compiler bug: the macro does not have any arguments")
        }

        return "(\(argument), \(literal: argument.description))"
    }
}

@main
struct InstaceCountingPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        StringifyMacro.self,
    ]
}

public struct URLMacro: ExpressionMacro {
    public static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) throws -> ExprSyntax {
        guard let argument = node.arguments.first?.expression,
              let segments = argument.as(StringLiteralExprSyntax.self)?.segments,
              segments.count == 1,
              case .stringSegment(let literalSegment)? = segments.first else { throw URLMacroError.requiresStaticStringLiteral }

        guard let _ = URL(string: literalSegment.content.text) else {
            throw URLMacroError.malformedURL(urlString: "\(argument)")
        }
        return "URL(string: \(argument))!"
    }
}

enum URLMacroError: Error, CustomStringConvertible {
    case requiresStaticStringLiteral
    case malformedURL(urlString: String)

    var description: String {
        switch self {
        case .requiresStaticStringLiteral:
            return "#URL requires a static string literal"
        case .malformedURL(let urlString):
            return "The input URL is malformed: \(urlString)"
        }
    }
}

enum CountedMacro: MemberMacro {
    static func expansion(of node: AttributeSyntax, providingMembersOf declaration: some DeclGroupSyntax, in context: some MacroExpansionContext) throws -> [DeclSyntax] {
        let initialisers = declaration.memberBlock.members.compactMap { member in
            member.decl.as(InitializerDeclSyntax.self)
        }
        guard initialisers.count > 0 else {
            //context.diagnose(...)
            return []
        }
        let newInitialisers = initialisers.map(generateNewInitialiser).map(DeclSyntax.init)
        return ["var count = 0"] + newInitialisers
    }

    static func generateNewInitialiser(from initialiser: InitializerDeclSyntax) -> InitializerDeclSyntax {
        var newInitialiser = initialiser
        // add parameter
        let newParameterList = FunctionParameterListSyntax {
            newInitialiser.signature.parameterClause.parameters
            "count: Int"
        }
        newInitialiser.signature.parameterClause.parameters = newParameterList

        // add statement initialising count
        newInitialiser.body?.statements.append("self.count = count")

        return newInitialiser
    }
}

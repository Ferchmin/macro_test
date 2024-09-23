// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation

/// A macro that produces both a value and a string containing the
/// source code that generated the value. For example,
///
///     #stringify(x + y)
///
/// produces a tuple `(x + y, "x + y")`.
@freestanding(expression)
public macro stringify<T>(_ value: T) -> (T, String) = #externalMacro(module: "InstaceCountingMacros", type: "StringifyMacro")

@freestanding(expression)
public macro URL(_ stringLiteral: String) -> URL = #externalMacro(module: "InstaceCountingMacros", type: "URLMacro")

@freestanding(expression)
public macro Counted<T>(_ value: T) -> T = #externalMacro(module: "InstaceCountingMacros", type: "CountedMacro")

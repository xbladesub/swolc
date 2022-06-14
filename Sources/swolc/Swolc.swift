import ArgumentParser
import Foundation

@main
struct Swolc: ParsableCommand {
    static var configuration = CommandConfiguration(
        abstract: "Solidity ABI manipulations",
        version: "1.0.0",
        subcommands: []
    )

    @Option(name: [.customShort("a"), .customLong("abi")], help: "Solidity file path", completion: .)
    var abi: String!
}

// MARK: - 💠 Internal Interface

extension Swolc {
    func run() throws {
        print(abi)
    }
}

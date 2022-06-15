import ArgumentParser
import Foundation
import TLogger

@main
struct Swolc: ParsableCommand {
    static var configuration = CommandConfiguration(
        abstract: "Solidity ABI manipulations",
        version: "1.0.0",
        subcommands: []
    )

    // @Option(name: [.customShort("a"), .customLong("abi")], help: "Solidity file path")
    // var solidilyFilePath: String!

    @Argument(help: "solidity file including contract/s")
    var solidilyFilePath: String!
}

extension Swolc {
    func run() throws {
        let jsonScrapperRange = (top: "Contract JSON ABI", bottom: "\n\n")
        let contractNameScrapperRange = (top: "======= ", bottom: " =======")
        var jsonArray: [String] = []
        var contractNameArray: [String] = []
        var resultDict: [String: String] = [:]

        if isSolidityFilePathURL(solidilyFilePath) {
            do {
                try safeShell("which solc") {
                    if $0.contains("not found") {
                        Log.error("'solc' is not installed'", shouldLogContext: false)
                        RunLoop.exit()
                    }
                }

                try safeShell("solc --abi \(solidilyFilePath!)") { solcABIRes in
                    let resModified = solcABIRes + "\n"

                    let topRanges = resModified.ranges(of: jsonScrapperRange.top)
                    let bottomRanges = resModified.ranges(of: jsonScrapperRange.bottom)

                    let topNameRanges = resModified.ranges(of: contractNameScrapperRange.top)
                    let bottomNameRanges = resModified.ranges(of: contractNameScrapperRange.bottom)

                    let ranges = zip(topRanges, bottomRanges)
                    let nameRanges = zip(topNameRanges, bottomNameRanges)

                    ranges.forEach {
                        let finalRange = $0.upperBound ..< $1.lowerBound
                        let abiJSONString = String(describing: resModified)[finalRange]
                        jsonArray.append(String(abiJSONString))
                    }

                    nameRanges.forEach {
                        let finalRange = $0.upperBound ..< $1.lowerBound
                        let rawLine = String(describing: resModified)[finalRange]
                        if let contractName = rawLine.components(separatedBy: ":").last {
                            contractNameArray.append(contractName)
                        }
                    }

                    resultDict = Dictionary(uniqueKeysWithValues: zip(contractNameArray, jsonArray))

                    if resultDict.count > 1 {
                        print("Found contracts: \n".cyan)
                        let contractsString = contractNameArray.enumerated().map { "\($0 + 1) - \($1)" }.joined(separator: "\n")
                        print(contractsString.cyan)
                        print("\ncotract number: ".cyan, terminator: "")
                        guard let input = readLine(), let num = Int(input) else {
                            Log.error("invalid number")
                            return RunLoop.exit()
                        }

                        let selectedContractName = contractNameArray[num - 1]
                        
                        let contractABIJsonString = resultDict[selectedContractName]!.asJsonString
                        print("\n" + contractABIJsonString.yellow)

                        try! safeShell("echo '\(contractABIJsonString)' | tr -d '\n' | pbcopy") { _ in }
                        print("\n'\(selectedContractName)' ABI copied to clipboard".cyan)
                    } else {
                        let contractName = resultDict.keys.first!
                        let contractABIJsonString = resultDict.values.first!.asJsonString
                        print("\n" + contractABIJsonString.yellow)
                        try! safeShell("echo '\(contractABIJsonString)' | tr -d '\n' | pbcopy") { _ in }
                        print("\n'\(contractName)' ABI copied to clipboard".cyan)
                    }
                    RunLoop.exit()
                }
                RunLoop.enter()
            } catch {}
        } else {
            Log.error("Invalid solidity file path", shouldLogContext: false)
        }
    }
}

func isSolidityFilePathURL(_ urlString: String) -> Bool {
    guard let url = URL(string: urlString) else { return false }
    if FileManager.default.fileExists(atPath: url.path), url.pathExtension == "sol" {
        return true
    } else {
        return false
    }
}

func safeShell(_ command: String, completion: @escaping (String) -> Void) throws {
    let task = Process()
    let pipe = Pipe()

    task.standardOutput = pipe
    task.standardError = pipe
    task.arguments = ["-c", command]
    task.executableURL = URL(fileURLWithPath: "/bin/zsh")
    task.standardInput = nil

    task.terminationHandler = { _ in
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8)!

        completion(output)
    }

    try task.run()
}

func convertIntoJSONString(arrayObject: [Any]) -> String? {
    do {
        let jsonData: Data = try JSONSerialization.data(withJSONObject: arrayObject, options: [])
        if let jsonString = NSString(data: jsonData, encoding: String.Encoding.utf8.rawValue) {
            return jsonString as String
        }

    } catch let error as NSError {
        print("Array convertIntoJSON - \(error.description)")
    }
    return nil
}

extension String {
    var asJsonString: Self {
        let asJsonString = replacingOccurrences(of: "\"", with: "\\\"").replacingOccurrences(of: "\n", with: "")
        return asJsonString
    }
}

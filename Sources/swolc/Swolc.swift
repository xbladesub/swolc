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

    @Option(name: [.customShort("a"), .customLong("abi")], help: "Solidity file path")
    var solidilyFilePath: String!
}

extension Swolc {
    func run() throws {
        let scrapperRange = (top: "Contract JSON ABI", bottom: "\n\n")
        var jsonArray: [String] = []

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
                    let topRanges = resModified.ranges(of: scrapperRange.top)
                    let bottomRanges = resModified.ranges(of: scrapperRange.bottom)
                    let ranges = zip(topRanges, bottomRanges)
                    ranges.forEach {
                        let finalRange = $0.upperBound ..< $1.lowerBound
                        let abiJSONString = String(describing: resModified)[finalRange]
                        jsonArray.append(String(abiJSONString))
                    }

                    try! safeShell("echo $'\(jsonArray[0])' | pbcopy") { _ in }
                    // print("total ABIs: \(jsonArray.count)")
                    print(jsonArray[0]) 
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

typealias LineState = (
    // pointer to a C string representing a line
    linePtr: UnsafeMutablePointer<CChar>?,
    linecap: Int,
    filePtr: UnsafeMutablePointer<FILE>?
)

/// Returns a sequence which iterates through all lines of the the file at the URL.
///
/// - Parameter url: file URL of a file to read
/// - Returns: a Sequence which lazily iterates through lines of the file
///
/// - warning: the caller of this function **must** iterate through all lines of the file, since aborting iteration midway will leak memory and a file pointer
/// - precondition: the file must be UTF8-encoded (which includes, ASCII-encoded)
func lines(ofFile fileURL: URL) -> UnfoldSequence<String, LineState> {
    let initialState: LineState = (linePtr: nil, linecap: 0, filePtr: fopen(fileURL.path, "r"))
    return sequence(state: initialState, next: { state -> String? in
        if getline(&state.linePtr, &state.linecap, state.filePtr) > 0,
           let theLine = state.linePtr
        {
            return String(cString: theLine)
        } else {
            if let actualLine = state.linePtr { free(actualLine) }
            fclose(state.filePtr)
            return nil
        }
    })
}

import Foundation

final class ProcessRunner {

    struct Result {
        let exitCode: Int32
        let output: String
        let error: String
    }

    static func run(
        executablePath: String,
        arguments: [String] = [],
        completion: @escaping (Result) -> Void
    ) {
        DispatchQueue.global(qos: .utility).async {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: executablePath)
            process.arguments = arguments

            let outputPipe = Pipe()
            let errorPipe = Pipe()
            process.standardOutput = outputPipe
            process.standardError = errorPipe

            do {
                try process.run()
                process.waitUntilExit()

                let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
                let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()

                let result = Result(
                    exitCode: process.terminationStatus,
                    output: String(data: outputData, encoding: .utf8) ?? "",
                    error: String(data: errorData, encoding: .utf8) ?? ""
                )

                DispatchQueue.main.async {
                    completion(result)
                }
            } catch {
                let result = Result(
                    exitCode: -1,
                    output: "",
                    error: error.localizedDescription
                )
                DispatchQueue.main.async {
                    completion(result)
                }
            }
        }
    }
}

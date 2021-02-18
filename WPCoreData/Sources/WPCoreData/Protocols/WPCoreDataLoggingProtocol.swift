import Foundation

public protocol WPCoreDataLogging {
    func debug(_ message: String)
    func info(_ message: String)
    func error(_ message: String)
    func fatal(_ message: String)
}

struct DebugCoreDataLogging: WPCoreDataLogging {
    func debug(_ message: String) {
        debugPrint("DEBUG: \(message)")
    }

    func info(_ message: String) {
        debugPrint("INFO: \(message)")
    }

    func error(_ message: String) {
        debugPrint("ERROR: \(message)")
    }

    func fatal(_ message: String) {
        debugPrint("FATAL: \(message)")
    }
}

import Foundation

/// A tiny assertion recorder. Enough to fail a run loudly and say why.
enum Check {
    nonisolated(unsafe) private static var failures: [String] = []

    static func that(_ name: String, _ got: some Equatable, equals want: some Equatable) {
        let ok = "\(got)" == "\(want)"
        report(name, ok, ok ? "\(got)" : "got \(got), want \(want)")
    }

    static func that(_ name: String, _ ok: Bool, _ detail: String) {
        report(name, ok, detail)
    }

    private static func report(_ name: String, _ ok: Bool, _ detail: String) {
        print("\(ok ? "ok  " : "FAIL") \(name): \(detail)")
        if !ok { failures.append(name) }
    }

    static func finish() -> Never {
        if failures.isEmpty {
            print("all checks passed")
            exit(0)
        }
        print("FAILED: \(failures.joined(separator: ", "))")
        exit(1)
    }
}

// SPDX-License-Identifier: MIT
// Trains the bundled Dataset folder with Brush once, at launch, and prints
// iterations per second and peak memory to stdout (shown by `devicectl
// process launch --console`) and to Documents/brush-spike-result.json.

import Darwin
import Foundation
import MacallaBrush
import SwiftUI
import Synchronization

@main
struct BrushSpikeApp: App {
    @State private var status = "Starting…"

    var body: some Scene {
        WindowGroup {
            Text(status)
                .font(.body.monospaced())
                .padding()
                .task { status = await SpikeRun.start() }
        }
    }
}

/// Shared between the training thread and its C progress callback.
final class SpikeProgress: Sendable {
    let latest = Mutex<(iter: UInt32, rate: Double)>((0, 0))
}

enum SpikeRun {
    static func start() async -> String {
        let iterations = UInt32(ProcessInfo.processInfo.environment["BRUSH_ITERS"] ?? "") ?? 7000
        guard let dataset = Bundle.main.url(forResource: "Dataset", withExtension: nil) else {
            return report("No Dataset folder in the app bundle")
        }
        let docs = URL.documentsDirectory
        let outPLY = docs.appending(path: "brush-spike.ply")
        print("BRUSH start dataset=\(dataset.path) iterations=\(iterations) device=\(deviceModel())")

        let progress = SpikeProgress()
        let started = Date()
        let code: Int32 = await withCheckedContinuation { done in
            let thread = Thread {
                let rc = macalla_brush_train(
                    dataset.path, iterations, outPLY.path,
                    { iter, total, rate, user in
                        let progress = Unmanaged<SpikeProgress>.fromOpaque(user!).takeUnretainedValue()
                        progress.latest.withLock { $0 = (iter, rate) }
                        if iter % 500 == 0 || iter == total {
                            print(String(format: "BRUSH iter %u/%u %.2f it/s footprint %.0f MB",
                                         iter, total, rate, Double(Memory.current()) / 1_048_576))
                        }
                    },
                    Unmanaged.passUnretained(progress).toOpaque())
                done.resume(returning: rc)
            }
            thread.stackSize = 16 << 20
            thread.start()
        }
        let elapsed = Date().timeIntervalSince(started)
        let last = progress.latest.withLock { $0 }
        let result: [String: Any] = [
            "device": deviceModel(),
            "exit_code": Int(code),
            "iterations_done": Int(last.iter),
            "iterations_requested": Int(iterations),
            "iters_per_sec": last.rate,
            "wall_seconds": elapsed,
            "peak_footprint_mb": Double(Memory.peak()) / 1_048_576,
            "memory_limit_mb": Double(os_proc_available_memory() + Int(Memory.current())) / 1_048_576,
        ]
        let json = (try? JSONSerialization.data(withJSONObject: result, options: [.sortedKeys])) ?? Data()
        try? json.write(to: docs.appending(path: "brush-spike-result.json"))
        return report("BRUSH RESULT " + (String(data: json, encoding: .utf8) ?? "{}"))
    }

    private static func report(_ line: String) -> String {
        print(line)
        return line
    }

    private static func deviceModel() -> String {
        var info = utsname()
        uname(&info)
        return withUnsafeBytes(of: &info.machine) { String(decoding: $0.prefix { $0 != 0 }, as: UTF8.self) }
    }
}

enum Memory {
    private static func vmInfo() -> task_vm_info_data_t? {
        var info = task_vm_info_data_t()
        var count = mach_msg_type_number_t(MemoryLayout<task_vm_info_data_t>.size / MemoryLayout<integer_t>.size)
        let kr = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                task_info(mach_task_self_, task_flavor_t(TASK_VM_INFO), $0, &count)
            }
        }
        return kr == KERN_SUCCESS ? info : nil
    }

    /// Bytes the system charges this process for (what jetsam compares to the limit).
    static func current() -> UInt64 { vmInfo()?.phys_footprint ?? 0 }

    /// Peak of `current()` over the process lifetime.
    static func peak() -> UInt64 { vmInfo().map { UInt64($0.ledger_phys_footprint_peak) } ?? 0 }
}

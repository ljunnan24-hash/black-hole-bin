import AppKit
import Foundation

@MainActor
enum SelfTest {
    static func run() -> Int {
        _ = NSApplication.shared
        let controller = TrashController()
        let previousReducedMotion = UserDefaults.standard.object(forKey: Defaults.reduceMotion)
        UserDefaults.standard.set(true, forKey: Defaults.reduceMotion)
        defer {
            if let previousReducedMotion {
                UserDefaults.standard.set(previousReducedMotion, forKey: Defaults.reduceMotion)
            } else {
                UserDefaults.standard.removeObject(forKey: Defaults.reduceMotion)
            }
        }

        let view = BlackHoleView(frame: NSRect(x: 0, y: 0, width: 264, height: 264))
        view.trashController = controller

        guard waitUntil({ view.renderer.isReady || view.renderer.lastError != nil }, timeout: 8) else {
            print("SELF-TEST FAIL: upstream WebGL renderer timed out")
            return 1
        }
        if let rendererError = view.renderer.lastError {
            print("SELF-TEST FAIL: upstream WebGL renderer: \(rendererError)")
            return 1
        }

        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("black-hole-bin-self-test-\(UUID().uuidString).txt")

        do {
            try Data("event horizon".utf8).write(to: fileURL)
        } catch {
            print("SELF-TEST FAIL: unable to create fixture: \(error)")
            return 1
        }

        defer {
            try? FileManager.default.removeItem(at: fileURL)
        }

        guard view.acceptDroppedURLs([fileURL]) else {
            print("SELF-TEST FAIL: drop target rejected a local file URL")
            return 1
        }

        guard waitUntil({
            controller.canUndo && !FileManager.default.fileExists(atPath: fileURL.path)
        }, timeout: 8) else {
            print("SELF-TEST FAIL: drag pipeline did not recycle the fixture")
            return 1
        }

        let undoResult = ResultBox<Result<Int, Error>>()
        controller.undoLastBatch { result in
            undoResult.value = result
        }

        guard wait(for: undoResult, timeout: 8) else {
            print("SELF-TEST FAIL: undo timed out")
            return 1
        }

        do {
            let count = try undoResult.value?.get()
            guard count == 1, FileManager.default.fileExists(atPath: fileURL.path), !controller.canUndo else {
                print("SELF-TEST FAIL: undo postconditions were not met")
                return 1
            }
        } catch {
            print("SELF-TEST FAIL: undo error: \(error)")
            return 1
        }

        print("SELF-TEST PASS: recycle and undo")
        return 0
    }

    private static func wait<T>(for result: ResultBox<T>, timeout: TimeInterval) -> Bool {
        waitUntil({ result.value != nil }, timeout: timeout)
    }

    private static func waitUntil(_ condition: () -> Bool, timeout: TimeInterval) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while !condition(), Date() < deadline {
            RunLoop.current.run(mode: .default, before: Date().addingTimeInterval(0.05))
        }
        return condition()
    }
}

@MainActor
private final class ResultBox<Value> {
    var value: Value?
}

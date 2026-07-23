import AppKit

@MainActor
final class TrashController {
    struct TrashedItem: Sendable {
        let originalURL: URL
        let trashURL: URL
    }

    enum TrashError: LocalizedError {
        case noItems
        case partialFailure(restored: Int, failed: Int)

        var errorDescription: String? {
            switch self {
            case .noItems:
                return "没有可撤销的投放"
            case .partialFailure(let restored, let failed):
                return "恢复了 \(restored) 个项目，\(failed) 个项目恢复失败"
            }
        }
    }

    private(set) var lastBatch: [TrashedItem] = []
    var canUndo: Bool { !lastBatch.isEmpty }

    func recycle(
        _ urls: [URL],
        completion: @escaping @MainActor @Sendable (Result<Int, Error>) -> Void
    ) {
        let uniqueURLs = Array(Set(urls.map(\.standardizedFileURL)))
        guard !uniqueURLs.isEmpty else {
            completion(.failure(TrashError.noItems))
            return
        }

        NSWorkspace.shared.recycle(uniqueURLs) { [weak self] mapping, error in
            MainActor.assumeIsolated {
                if let error {
                    completion(.failure(error))
                    return
                }

                self?.lastBatch = mapping.map { source, destination in
                    TrashedItem(originalURL: source, trashURL: destination)
                }
                completion(.success(mapping.count))
            }
        }
    }

    func undoLastBatch(
        completion: @escaping @MainActor @Sendable (Result<Int, Error>) -> Void
    ) {
        guard !lastBatch.isEmpty else {
            completion(.failure(TrashError.noItems))
            return
        }

        let batch = lastBatch
        lastBatch = []

        var restored = 0
        var failedItems: [TrashedItem] = []
        let fileManager = FileManager.default

        for item in batch {
            do {
                let parent = item.originalURL.deletingLastPathComponent()
                if !fileManager.fileExists(atPath: parent.path) {
                    try fileManager.createDirectory(at: parent, withIntermediateDirectories: true)
                }
                try fileManager.moveItem(at: item.trashURL, to: item.originalURL)
                restored += 1
            } catch {
                failedItems.append(item)
            }
        }

        lastBatch = failedItems
        if failedItems.isEmpty {
            completion(.success(restored))
        } else {
            completion(.failure(TrashError.partialFailure(restored: restored, failed: failedItems.count)))
        }
    }
}

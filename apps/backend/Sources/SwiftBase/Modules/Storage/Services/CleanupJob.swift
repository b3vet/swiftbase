import Foundation

/// Background job for cleaning up orphaned and missing files
public actor CleanupJob {
    private let storageService: StorageService
    private let logger: LoggerService
    private let interval: TimeInterval
    private var task: Task<Void, Never>?

    public init(
        storageService: StorageService,
        interval: TimeInterval = 3600, // 1 hour default
        logger: LoggerService = .shared
    ) {
        self.storageService = storageService
        self.interval = interval
        self.logger = logger
    }

    /// Start the cleanup job
    public func start() {
        guard task == nil else {
            logger.warning("Cleanup job already running")
            return
        }

        logger.info("Starting file cleanup job (interval: \(interval)s)")

        task = Task {
            while !Task.isCancelled {
                do {
                    // Wait for interval
                    try await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))

                    // Run cleanup
                    await runCleanup()
                } catch {
                    if Task.isCancelled {
                        break
                    }
                    logger.error("Cleanup job error", error: error)
                }
            }
        }
    }

    /// Stop the cleanup job
    public func stop() {
        task?.cancel()
        task = nil
        logger.info("Stopped file cleanup job")
    }

    /// Run cleanup manually
    public func runCleanup() async {
        logger.info("Running file cleanup...")

        do {
            // Clean up orphaned files (files on disk without DB records)
            let orphanedCount = try await storageService.cleanupOrphanedFiles()

            // Clean up missing files (DB records without files on disk)
            let missingCount = try await storageService.cleanupMissingFiles()

            logger.info("Cleanup completed: \(orphanedCount) orphaned, \(missingCount) missing")
        } catch {
            logger.error("Cleanup failed", error: error)
        }
    }
}

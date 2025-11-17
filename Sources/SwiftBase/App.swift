import Foundation
import Hummingbird

/// Main application class that manages the HTTP server and application lifecycle
public struct App {

    // MARK: - Build Application

    public static func build(
        host: String,
        port: Int,
        configService: ConfigService,
        logger: LoggerService
    ) async throws -> some ApplicationProtocol {
        // Initialize database
        let config = configService.get()
        let dbService = try DatabaseService(
            path: config.database.path,
            enableWAL: config.database.enableWAL
        )

        logger.info("Database initialized at: \(config.database.path)")

        // Initialize auth services
        let jwtService = JWTService(
            secret: config.auth.jwtSecret.isEmpty ? "default-secret-change-in-production" : config.auth.jwtSecret,
            accessTokenExpiry: config.auth.accessTokenExpiry,
            refreshTokenExpiry: config.auth.refreshTokenExpiry
        )
        let passwordService = PasswordService(cost: config.auth.bcryptCost)
        let sessionService = SessionService(dbService: dbService)

        // Initialize auth controllers
        let userAuthController = UserAuthController(
            dbService: dbService,
            jwtService: jwtService,
            passwordService: passwordService,
            sessionService: sessionService
        )

        let adminAuthController = AdminAuthController(
            dbService: dbService,
            jwtService: jwtService,
            passwordService: passwordService,
            sessionService: sessionService
        )

        // Initialize query service and controller
        let queryService = QueryService(dbService: dbService)
        let queryController = QueryController(
            queryService: queryService,
            jwtService: jwtService
        )

        // Initialize collection service and controller
        let collectionService = CollectionService(dbService: dbService)
        let collectionController = CollectionController(
            collectionService: collectionService,
            jwtService: jwtService
        )

        // Initialize storage service and controller
        let storageService = StorageService(
            dbService: dbService,
            storageDirectory: config.storage.path,
            maxFileSize: config.storage.maxFileSize
        )
        let storageController = StorageController(
            storageService: storageService,
            jwtService: jwtService
        )

        // Start file cleanup job
        let cleanupJob = CleanupJob(storageService: storageService)
        await cleanupJob.start()

        let router = Router()

        // Add global middleware (order matters!)
        // 1. CORS - handle preflight and add CORS headers
        router.middlewares.add(CORSMiddleware())

        // 2. Logging - log all requests/responses
        router.middlewares.add(LoggingMiddleware(logger: logger))

        // 3. Error handling - catch and format all errors
        router.middlewares.add(ErrorMiddleware(logger: logger))

        // 4. Versioning - informational only (header-based, not path-based)
        // Path-based versioning disabled by default - routes are at /health, /api/query, not /api/v1/*
        router.middlewares.add(VersioningMiddleware(enforcePathVersioning: false))

        // 5. Validation - validate request size, content-type, etc.
        router.middlewares.add(ValidationMiddleware())

        // Health check endpoints
        router.get("/health") { _, _ -> HealthCheckResponse in
            return HealthCheckResponse(
                status: "healthy",
                timestamp: ISO8601DateFormatter().string(from: Date()),
                version: "0.1.0"
            )
        }

        router.get("/health/db") { _, _ -> DatabaseHealthResponse in
            do {
                let health = try await dbService.healthCheck()
                return DatabaseHealthResponse(
                    status: "healthy",
                    database: health
                )
            } catch {
                return DatabaseHealthResponse(
                    status: "unhealthy",
                    database: nil,
                    error: error.localizedDescription
                )
            }
        }

        // API info endpoint
        router.get("/api") { _, _ -> APIInfoResponse in
            return APIInfoResponse(
                name: "SwiftBase API",
                version: "0.1.0",
                description: "Single-binary backend platform"
            )
        }

        // User authentication routes (public)
        router.post("/api/auth/register", use: userAuthController.register)
        router.post("/api/auth/login", use: userAuthController.login)
        router.post("/api/auth/refresh", use: userAuthController.refresh)

        // User authentication routes (protected)
        router.group()
            .add(middleware: JWTMiddleware(jwtService: jwtService))
            .post("/api/auth/logout", use: userAuthController.logout)
            .get("/api/auth/me", use: userAuthController.getCurrentUser)

        // Admin authentication routes (public)
        router.post("/api/admin/login", use: adminAuthController.login)
        router.post("/api/admin/refresh", use: adminAuthController.refresh)

        // Admin authentication routes (protected)
        router.group()
            .add(middleware: JWTMiddleware(jwtService: jwtService, requireAdmin: true))
            .post("/api/admin/logout", use: adminAuthController.logout)
            .get("/api/admin/me", use: adminAuthController.getCurrentAdmin)

        // Query endpoints (protected - requires authentication)
        router.group()
            .add(middleware: JWTMiddleware(jwtService: jwtService))
            .post("/api/query", use: queryController.execute)
            .get("/api/collections/:collection", use: queryController.getCollectionInfo)

        // Custom query management (admin only)
        router.group()
            .add(middleware: JWTMiddleware(jwtService: jwtService, requireAdmin: true))
            .get("/api/admin/queries", use: queryController.listCustomQueries)

        // Collection management (protected)
        router.group()
            .add(middleware: JWTMiddleware(jwtService: jwtService))
            .get("/api/admin/collections", use: collectionController.listCollections)
            .get("/api/admin/collections/:name", use: collectionController.getCollection)
            .get("/api/admin/collections/:name/stats", use: collectionController.getCollectionStats)

        // Collection management (admin only)
        router.group()
            .add(middleware: JWTMiddleware(jwtService: jwtService, requireAdmin: true))
            .post("/api/admin/collections", use: collectionController.createCollection)
            .put("/api/admin/collections/:name", use: collectionController.updateCollection)
            .delete("/api/admin/collections/:name", use: collectionController.deleteCollection)

        // Bulk operations (protected)
        router.group()
            .add(middleware: JWTMiddleware(jwtService: jwtService))
            .post("/api/bulk", use: collectionController.executeBulkOperations)

        // Storage endpoints (protected - requires authentication)
        router.group()
            .add(middleware: JWTMiddleware(jwtService: jwtService))
            .post("/api/storage/upload", use: storageController.uploadFile)
            .get("/api/storage/files/:id", use: storageController.downloadFile)
            .get("/api/storage/files/:id/info", use: storageController.getFileInfo)
            .delete("/api/storage/files/:id", use: storageController.deleteFile)
            .get("/api/storage/files", use: storageController.listFiles)
            .get("/api/storage/search", use: storageController.searchFiles)
            .get("/api/storage/stats", use: storageController.getStorageStats)

        // Storage cleanup (admin only)
        router.group()
            .add(middleware: JWTMiddleware(jwtService: jwtService, requireAdmin: true))
            .post("/api/admin/storage/cleanup", use: storageController.cleanupOrphanedFiles)

        // Admin UI static file handler
        let adminHandler = AdminUIHandler(logger: logger)

        // Single handler for all admin paths
        // Handles: /admin, /admin/, /admin/*, /admin/**
        router.get("/admin") { request, context in
            try await adminHandler.handle(request: request, context: context)
        }
        router.get("/admin/**") { request, context in
            try await adminHandler.handle(request: request, context: context)
        }

        // Create application
        let app = Application(
            router: router,
            configuration: .init(
                address: .hostname(host, port: port)
            )
        )

        logger.info("SwiftBase application configured on \(host):\(port)")

        return app
    }

    // MARK: - Run Server

    public static func run(
        host: String,
        port: Int,
        configService: ConfigService,
        logger: LoggerService
    ) async throws {
        logger.info("Starting SwiftBase server on \(host):\(port)")

        let app = try await build(
            host: host,
            port: port,
            configService: configService,
            logger: logger
        )

        do {
            try await app.runService()
        } catch {
            logger.error("Server failed to start", error: error)
            throw AppError.internalServerError("Failed to start server: \(error)")
        }
    }
}

// MARK: - Response Models

struct HealthCheckResponse: ResponseEncodable {
    let status: String
    let timestamp: String
    let version: String
}

struct DatabaseHealthResponse: ResponseEncodable {
    let status: String
    let database: DatabaseHealth?
    let error: String?

    init(status: String, database: DatabaseHealth?, error: String? = nil) {
        self.status = status
        self.database = database
        self.error = error
    }
}

struct APIInfoResponse: ResponseEncodable {
    let name: String
    let version: String
    let description: String
}

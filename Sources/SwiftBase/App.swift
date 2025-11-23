import Foundation
import Hummingbird
import HummingbirdWebSocket
@_spi(WSInternal) import WSCore

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

        // Initialize realtime module (must be initialized early to wire up services)
        let realtimeModule = await RealtimeModule(jwtService: jwtService, logger: logger)

        // Initialize query service and controller
        let queryService = QueryService(dbService: dbService)
        await queryService.setBroadcastService(realtimeModule.broadcastService)

        let savedQueryService = SavedQueryService(dbService: dbService, logger: logger)
        let queryController = QueryController(
            queryService: queryService,
            jwtService: jwtService,
            savedQueryService: savedQueryService
        )

        // Initialize saved query controller
        let savedQueryController = SavedQueryController(
            savedQueryService: savedQueryService,
            jwtService: jwtService,
            logger: logger
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

        // Initialize user service and controller
        let userService = UserService(
            dbService: dbService,
            passwordService: passwordService,
            sessionService: sessionService
        )
        let userController = UserController(
            userService: userService,
            jwtService: jwtService
        )

        let router = Router(context: BasicWebSocketRequestContext.self)

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

        // Saved queries (admin only)
        router.group()
            .add(middleware: JWTMiddleware(jwtService: jwtService, requireAdmin: true))
            .get("/api/admin/saved-queries", use: savedQueryController.list)
            .get("/api/admin/saved-queries/:name", use: savedQueryController.get)
            .post("/api/admin/saved-queries", use: savedQueryController.create)
            .put("/api/admin/saved-queries/:name", use: savedQueryController.update)
            .delete("/api/admin/saved-queries/:name", use: savedQueryController.delete)

        // Execute saved query by name (requires authentication)
        router.group()
            .add(middleware: JWTMiddleware(jwtService: jwtService))
            .post("/api/query/execute/:queryName", use: queryController.executeByName)

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

        // User management (admin only)
        router.group()
            .add(middleware: JWTMiddleware(jwtService: jwtService, requireAdmin: true))
            .get("/api/admin/users", use: userController.listUsers)
            .get("/api/admin/users/stats", use: userController.getUserStats)
            .get("/api/admin/users/:id", use: userController.getUser)
            .post("/api/admin/users", use: userController.createUser)
            .put("/api/admin/users/:id", use: userController.updateUser)
            .delete("/api/admin/users/:id", use: userController.deleteUser)
            .post("/api/admin/users/:id/verify-email", use: userController.verifyEmail)
            .post("/api/admin/users/:id/revoke-sessions", use: userController.revokeSessions)

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

        // WebSocket endpoint for realtime subscriptions
        router.ws("/api/realtime") { inbound, outbound, context in
            let wsContext = WebSocketContext(request: context.request)
            await realtimeModule.webSocketHub.handleConnection(
                inbound: inbound,
                outbound: outbound,
                context: wsContext
            )
        }

        // Realtime statistics endpoint (admin only)
        router.group()
            .add(middleware: JWTMiddleware(jwtService: jwtService, requireAdmin: true))
            .get("/api/admin/realtime/stats") { _, _ -> RealtimeStatistics in
                return await realtimeModule.getStatistics()
            }

        // Create application with WebSocket support
        // Use buildApplication to ensure WebSocket upgrades are handled correctly
        let app = buildApplication(
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

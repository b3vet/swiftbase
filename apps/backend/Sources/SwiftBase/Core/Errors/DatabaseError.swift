import Foundation

/// Database-specific errors
public enum DatabaseError: Error, CustomStringConvertible {
    case connectionFailed(String)
    case queryFailed(String)
    case migrationFailed(String)
    case transactionFailed(String)
    case constraintViolation(String)
    case notFound(String)
    case duplicateEntry(String)
    case invalidQuery(String)

    public var description: String {
        switch self {
        case .connectionFailed(let msg):
            return "Database connection failed: \(msg)"
        case .queryFailed(let msg):
            return "Query failed: \(msg)"
        case .migrationFailed(let msg):
            return "Migration failed: \(msg)"
        case .transactionFailed(let msg):
            return "Transaction failed: \(msg)"
        case .constraintViolation(let msg):
            return "Constraint violation: \(msg)"
        case .notFound(let msg):
            return "Not found: \(msg)"
        case .duplicateEntry(let msg):
            return "Duplicate entry: \(msg)"
        case .invalidQuery(let msg):
            return "Invalid query: \(msg)"
        }
    }
}

import Foundation

/// Validation error for field-level validation failures
public struct ValidationError: Error, CustomStringConvertible, Sendable {
    public let field: String
    public let message: String

    public init(field: String, message: String) {
        self.field = field
        self.message = message
    }

    public var description: String {
        return "\(field): \(message)"
    }

    // MARK: - Common Validation Errors

    public static func required(_ field: String) -> ValidationError {
        return ValidationError(field: field, message: "This field is required")
    }

    public static func invalid(_ field: String, reason: String? = nil) -> ValidationError {
        let message = reason ?? "Invalid value"
        return ValidationError(field: field, message: message)
    }

    public static func tooShort(_ field: String, minLength: Int) -> ValidationError {
        return ValidationError(
            field: field,
            message: "Must be at least \(minLength) characters long"
        )
    }

    public static func tooLong(_ field: String, maxLength: Int) -> ValidationError {
        return ValidationError(
            field: field,
            message: "Must be no more than \(maxLength) characters long"
        )
    }

    public static func invalidEmail(_ field: String) -> ValidationError {
        return ValidationError(field: field, message: "Invalid email address")
    }

    public static func invalidFormat(_ field: String, format: String) -> ValidationError {
        return ValidationError(
            field: field,
            message: "Invalid format. Expected: \(format)"
        )
    }

    public static func outOfRange(_ field: String, min: Any?, max: Any?) -> ValidationError {
        var message = "Value out of range"
        if let min = min, let max = max {
            message = "Must be between \(min) and \(max)"
        } else if let min = min {
            message = "Must be at least \(min)"
        } else if let max = max {
            message = "Must be no more than \(max)"
        }
        return ValidationError(field: field, message: message)
    }

    public static func duplicate(_ field: String) -> ValidationError {
        return ValidationError(field: field, message: "This value already exists")
    }

    public static func custom(_ field: String, message: String) -> ValidationError {
        return ValidationError(field: field, message: message)
    }
}

// MARK: - Validator Helper

public struct Validator {

    public static func validateEmail(_ email: String) -> Bool {
        let emailRegex = #"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$"#
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }

    public static func validatePassword(_ password: String, minLength: Int = 8) -> [ValidationError] {
        var errors: [ValidationError] = []

        if password.count < minLength {
            errors.append(.tooShort("password", minLength: minLength))
        }

        return errors
    }

    public static func validateRequired(_ value: String?, field: String) -> ValidationError? {
        if value == nil || value?.isEmpty == true {
            return .required(field)
        }
        return nil
    }

    public static func validateLength(
        _ value: String,
        field: String,
        min: Int? = nil,
        max: Int? = nil
    ) -> [ValidationError] {
        var errors: [ValidationError] = []

        if let min = min, value.count < min {
            errors.append(.tooShort(field, minLength: min))
        }

        if let max = max, value.count > max {
            errors.append(.tooLong(field, maxLength: max))
        }

        return errors
    }

    public static func validateRange<T: Comparable>(
        _ value: T,
        field: String,
        min: T? = nil,
        max: T? = nil
    ) -> ValidationError? {
        if let min = min, value < min {
            return .outOfRange(field, min: min, max: nil)
        }

        if let max = max, value > max {
            return .outOfRange(field, min: nil, max: max)
        }

        return nil
    }
}

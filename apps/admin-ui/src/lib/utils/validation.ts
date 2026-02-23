// Validation utility functions

export const validation = {
  // Email validation
  isEmail(email: string): boolean {
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/
    return emailRegex.test(email)
  },

  // Password validation (minimum 8 characters)
  isValidPassword(password: string): boolean {
    return password.length >= 8
  },

  // Collection/field name validation (alphanumeric, underscore, starts with letter)
  isValidName(name: string): boolean {
    const nameRegex = /^[a-zA-Z][a-zA-Z0-9_]{0,49}$/
    return nameRegex.test(name)
  },

  // URL validation
  isUrl(url: string): boolean {
    try {
      new URL(url)
      return true
    } catch {
      return false
    }
  },

  // Check if string is valid JSON
  isValidJSON(str: string): boolean {
    try {
      JSON.parse(str)
      return true
    } catch {
      return false
    }
  },

  // Required field validation
  isRequired(value: any): boolean {
    if (value === null || value === undefined) return false
    if (typeof value === 'string') return value.trim().length > 0
    if (Array.isArray(value)) return value.length > 0
    return true
  },

  // Min length validation
  minLength(value: string, min: number): boolean {
    return value.length >= min
  },

  // Max length validation
  maxLength(value: string, max: number): boolean {
    return value.length <= max
  },

  // Number range validation
  inRange(value: number, min: number, max: number): boolean {
    return value >= min && value <= max
  }
}

// Form validation helper
export interface ValidationRule {
  validator: (value: any) => boolean
  message: string
}

export function validateField(value: any, rules: ValidationRule[]): string | null {
  for (const rule of rules) {
    if (!rule.validator(value)) {
      return rule.message
    }
  }
  return null
}

export function validateForm(data: Record<string, any>, rules: Record<string, ValidationRule[]>): Record<string, string> {
  const errors: Record<string, string> = {}

  for (const [field, fieldRules] of Object.entries(rules)) {
    const error = validateField(data[field], fieldRules)
    if (error) {
      errors[field] = error
    }
  }

  return errors
}

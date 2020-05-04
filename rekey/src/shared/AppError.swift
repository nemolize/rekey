enum AppError: Error {
    case accessibility(_ message: String, _ code: Int32? = nil)
}
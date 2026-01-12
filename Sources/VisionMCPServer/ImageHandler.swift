import Foundation

/// Handles image input from various formats (base64 data URLs, file paths)
/// and manages temporary file storage for Vision Framework processing.
enum ImageHandler {

    // MARK: - Errors

    enum Error: LocalizedError {
        case invalidBase64Format
        case invalidImageData
        case invalidMimeType(String)
        case fileNotFound(String)
        case tempFileCreationFailed

        var errorDescription: String? {
            switch self {
            case .invalidBase64Format:
                return "Invalid base64 format. Expected format: data:image/xxx;base64,..."
            case .invalidImageData:
                return "Failed to decode image data"
            case .invalidMimeType(let mimeType):
                return "Unsupported MIME type: \(mimeType)"
            case .fileNotFound(let path):
                return "File not found: \(path)"
            case .tempFileCreationFailed:
                return "Failed to create temporary file"
            }
        }
    }

    // MARK: - Public API

    /// Processes an image input and returns a file path for Vision Framework.
    /// - Parameter input: Base64 data URL or file path
    /// - Returns: URL to the image file (temp or original)
    /// - Throws: ImageHandler.Error
    static func processImageInput(_ input: String) async throws -> URL {
        // Check if it's a base64 data URL
        if input.hasPrefix("data:image/") {
            return try await decodeBase64AndSave(input)
        } else {
            // Assume it's a file path
            return try validateFilePath(input)
        }
    }

    /// Cleans up a temporary file if it exists.
    /// - Parameter url: URL of the file to clean up
    static func cleanup(_ url: URL) {
        guard url.path.contains("/tmp/") else {
            // Only clean up temp files, not user-provided files
            return
        }
        try? FileManager.default.removeItem(at: url)
    }

    // MARK: - Private Methods

    /// Decodes a base64 data URL and saves to a temporary file.
    private static func decodeBase64AndSave(_ dataURL: String) async throws -> URL {
        // Parse format: data:image/xxx;base64,...
        guard let range = dataURL.range(of: "base64,") else {
            throw Error.invalidBase64Format
        }

        let base64String = String(dataURL[range.upperBound...])

        // Extract MIME type for file extension
        guard let mimeTypeStart = dataURL.range(of: "data:image/"),
              let mimeTypeEnd = dataURL.range(of: ";", range: mimeTypeStart.upperBound..<dataURL.endIndex) else {
            throw Error.invalidBase64Format
        }

        let mimeType = String(dataURL[mimeTypeStart.upperBound..<mimeTypeEnd.lowerBound])

        // Decode base64
        guard let imageData = Data(base64Encoded: base64String) else {
            throw Error.invalidImageData
        }

        // Create temp file with appropriate extension
        let fileExtension = fileExtensionFor(mimeType: mimeType)
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("vision-mcp-\(UUID().uuidString)")
            .appendingPathExtension(fileExtension)

        // Write image data
        do {
            try imageData.write(to: tempURL)
        } catch {
            throw Error.tempFileCreationFailed
        }

        return tempURL
    }

    /// Validates that a file path exists and is accessible.
    private static func validateFilePath(_ path: String) throws -> URL {
        let url = URL(fileURLWithPath: path)

        guard FileManager.default.fileExists(atPath: path) else {
            throw Error.fileNotFound(path)
        }

        // Check if it's readable
        guard FileManager.default.isReadableFile(atPath: path) else {
            throw Error.fileNotFound(path)
        }

        return url
    }

    /// Maps MIME type to file extension.
    private static func fileExtensionFor(mimeType: String) -> String {
        switch mimeType.lowercased() {
        case "image/jpeg", "image/jpg":
            return "jpg"
        case "image/png":
            return "png"
        case "image/gif":
            return "gif"
        case "image/webp":
            return "webp"
        case "image/bmp", "image/x-bmp":
            return "bmp"
        case "image/tiff":
            return "tiff"
        default:
            // Default to png for unknown types
            return "png"
        }
    }
}

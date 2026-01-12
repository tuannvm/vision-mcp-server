import Foundation

/// Handles image input from various formats (base64 data URLs, file paths, remote URLs)
/// and manages temporary file storage for Vision Framework processing.
enum ImageHandler {

    // MARK: - Errors

    enum Error: LocalizedError {
        case invalidBase64Format
        case invalidImageData
        case invalidMimeType(String)
        case fileNotFound(String)
        case tempFileCreationFailed
        case invalidURL(String)
        case downloadFailed(String)
        case downloadTimeout(String)
        case unsupportedURLScheme(String)

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
            case .invalidURL(let url):
                return "Invalid URL: \(url)"
            case .downloadFailed(let url):
                return "Failed to download image from: \(url)"
            case .downloadTimeout(let url):
                return "Download timeout for: \(url)"
            case .unsupportedURLScheme(let scheme):
                return "Unsupported URL scheme: \(scheme). Only http:// and https:// are supported."
            }
        }

        var recoverySuggestion: String? {
            switch self {
            case .invalidBase64Format:
                return "Ensure the base64 string follows the format: data:image/png;base64,iVBORw0KG..."
            case .downloadFailed, .downloadTimeout:
                return "Check the URL is accessible and points to a valid image file"
            case .fileNotFound(let path):
                return "Verify the file path is correct: \(path)"
            default:
                return nil
            }
        }
    }

    // MARK: - Constants

    private static let downloadTimeout: TimeInterval = 30.0
    private static let maxImageSize: Int = 10 * 1024 * 1024 // 10MB

    // MARK: - Public API

    /// Processes an image input and returns a file path for Vision Framework.
    /// - Parameter input: Base64 data URL, local file path, or remote http/https URL
    /// - Returns: URL to the image file (temp or original)
    /// - Throws: ImageHandler.Error
    static func processImageInput(_ input: String) async throws -> URL {
        // Check if it's a base64 data URL (pasted image in Claude Code)
        if input.hasPrefix("data:image/") {
            return try await decodeBase64AndSave(input)
        }

        // Check if it's a remote URL (http/https)
        if input.hasPrefix("http://") || input.hasPrefix("https://") {
            return try await downloadImage(from: input)
        }

        // Assume it's a local file path
        return try validateFilePath(input)
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

    /// Downloads an image from a remote URL and saves to a temporary file.
    private static func downloadImage(from urlString: String) async throws -> URL {
        guard let url = URL(string: urlString) else {
            throw Error.invalidURL(urlString)
        }

        // Validate URL scheme
        guard url.scheme == "http" || url.scheme == "https" else {
            throw Error.unsupportedURLScheme(url.scheme ?? "unknown")
        }

        // Create URLSession configuration with timeout
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = downloadTimeout
        config.httpMaximumConnectionsPerHost = 1
        let session = URLSession(configuration: config)

        // Download the image
        do {
            let (data, response) = try await session.data(from: url)

            // Validate HTTP response
            guard let httpResponse = response as? HTTPURLResponse else {
                throw Error.downloadFailed(urlString)
            }

            guard httpResponse.statusCode == 200 else {
                throw Error.downloadFailed("\(urlString) (HTTP \(httpResponse.statusCode))")
            }

            // Check content type
            if let contentType = httpResponse.mimeType, !contentType.hasPrefix("image/") {
                throw Error.downloadFailed("URL did not return an image. Content-Type: \(contentType)")
            }

            // Check file size
            guard data.count <= maxImageSize else {
                let sizeMB = Double(data.count) / (1024 * 1024)
                throw Error.downloadFailed("Image too large: \(String(format: "%.1f", sizeMB))MB. Maximum size: 10MB")
            }

            // Determine file extension from Content-Type or URL
            let fileExtension: String
            if let contentType = httpResponse.mimeType {
                fileExtension = fileExtensionFor(mimeType: contentType)
            } else {
                let pathExtension = url.pathExtension
                fileExtension = pathExtension.isEmpty ? "jpg" : pathExtension
            }

            // Create temp file
            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent("vision-mcp-download-\(UUID().uuidString)")
                .appendingPathExtension(fileExtension)

            // Write image data
            do {
                try data.write(to: tempURL)
            } catch {
                throw Error.tempFileCreationFailed
            }

            return tempURL

        } catch let error as ImageHandler.Error {
            throw error
        } catch let urlError as URLError where urlError.code == .timedOut {
            throw Error.downloadTimeout(urlString)
        } catch {
            throw Error.downloadFailed("\(urlString): \(error.localizedDescription)")
        }
    }

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

import Vision

/// Wrapper around Apple's Vision Framework for OCR text extraction.
/// Uses Swift 6 concurrency patterns to wrap the synchronous Vision API.
@MainActor
final class VisionOCR {

    // MARK: - Errors

    enum Error: LocalizedError {
        case noTextFound
        case processingFailed(underlying: Swift.Error)

        var errorDescription: String? {
            switch self {
            case .noTextFound:
                return "No text was found in the image"
            case .processingFailed(let error):
                return "OCR processing failed: \(error.localizedDescription)"
            }
        }
    }

    // MARK: - Public API

    /// Extracts text from an image using Apple's Vision Framework.
    /// - Parameters:
    ///   - imagePath: Path to the image file
    ///   - languages: Recognition language codes (e.g., ["en-US", "zh-Hans"])
    ///   - level: Recognition level (.fast or .accurate)
    ///   - correction: Whether to use language correction
    /// - Returns: Extracted text from the image
    /// - Throws: VisionOCR.Error
    func extractText(
        from imagePath: String,
        languages: [String] = ["en-US"],
        level: VNRequestTextRecognitionLevel = .accurate,
        correction: Bool = true
    ) async throws -> String {
        // Wrap synchronous VNRecognizeTextRequest with withCheckedThrowingContinuation
        // and use Task.detached for CPU-bound OCR processing
        try await withCheckedThrowingContinuation { continuation in
            Task.detached(priority: .userInitiated) {
                do {
                    let request = VNRecognizeTextRequest()
                    request.recognitionLanguages = languages
                    request.recognitionLevel = level
                    request.usesLanguageCorrection = correction

                    let handler = VNImageRequestHandler(url: URL(fileURLWithPath: imagePath))

                    try handler.perform([request])

                    guard let observations = request.results, !observations.isEmpty else {
                        continuation.resume(returning: "")
                        return
                    }

                    // Extract text from observations
                    let extractedLines = observations.compactMap { observation -> String? in
                        guard let candidate = observation.topCandidates(1).first else { return nil }
                        return candidate.string
                    }

                    if extractedLines.isEmpty {
                        continuation.resume(throwing: VisionOCR.Error.noTextFound)
                    } else {
                        continuation.resume(returning: extractedLines.joined(separator: "\n"))
                    }

                } catch {
                    continuation.resume(throwing: VisionOCR.Error.processingFailed(underlying: error))
                }
            }
        }
    }
}

import Foundation

enum GitHubError: Error, LocalizedError {
    case invalidURL
    case requestFailed(Int)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL: return "الرابط الهندسي غير صالح."
        case .requestFailed(let code): return "تم رفض الوصول، كود الخطأ: \(code). راجع صلاحيات الـ PAT."
        }
    }
}

final class GitHubService {
    static let shared = GitHubService()
    private init() {}

    func triggerWorkflow(user: String, repo: String, token: String, code: String) async throws {
        let urlString = "https://api.github.com/repos/\(user)/\(repo)/dispatches"
        guard let url = URL(urlString: urlString) else { throw GitHubError.invalidURL }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let payload = GitHubDispatchPayload(eventType: "generate-dylib", clientPayload: ClientPayload(code: code))
        request.httpBody = try JSONEncoder().encode(payload)

        let (_, response) = try await URLSession.shared.data(for: request)
        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 204 {
            throw GitHubError.requestFailed(httpResponse.statusCode)
        }
    }

    func downloadDylib(user: String, repo: String, token: String) async throws -> URL {
        let urlString = "https://raw.githubusercontent.com/\(user)/\(repo)/main/generated_dylibs/OBSIDIAN_latest.dylib"
        guard let url = URL(urlString: urlString) else { throw GitHubError.invalidURL }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (localURL, response) = try await URLSession.shared.download(for: request)
        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
            throw GitHubError.requestFailed(httpResponse.statusCode)
        }

        let tempDir = FileManager.default.temporaryDirectory
        let destinationURL = tempDir.appendingPathComponent("OBSIDIAN_latest.dylib")

        try? FileManager.default.removeItem(at: destinationURL)
        try FileManager.default.moveItem(at: localURL, to: destinationURL)

        return destinationURL
    }
}

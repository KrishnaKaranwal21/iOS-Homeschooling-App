import Foundation
import CryptoKit

/// Atomic, account-scoped local files keep prototype content available across launches.
enum LocalArchive {
    private static func url(_ category: String, account: String) -> URL {
        let directory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Homeschool/LocalData", isDirectory: true)
        let key = SHA256.hash(data: Data(account.lowercased().utf8)).map { String(format: "%02x", $0) }.joined()
        return directory.appendingPathComponent("\(category)-\(key).json")
    }

    static func load<T: Decodable>(_ type: T.Type, category: String, account: String) -> T? {
        guard let data = try? Data(contentsOf: url(category, account: account)) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }

    @discardableResult
    static func save<T: Encodable>(_ value: T, category: String, account: String) -> Bool {
        do {
            let destination = url(category, account: account)
            try FileManager.default.createDirectory(at: destination.deletingLastPathComponent(), withIntermediateDirectories: true)
            try JSONEncoder().encode(value).write(to: destination, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
            return true
        } catch { return false }
    }

    static func remove(_ category: String, account: String) {
        try? FileManager.default.removeItem(at: url(category, account: account))
    }
}

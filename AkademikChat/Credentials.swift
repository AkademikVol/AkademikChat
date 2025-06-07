import Foundation
import CryptoKit

struct Credentials {
    private static let passwordKey = "hashed_password"

    static func hash(_ password: String) -> String {
        let data = Data(password.utf8)
        let digest = SHA256.hash(data: data)
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    static func storeHashedPassword(_ password: String) {
        let hashed = hash(password)
        UserDefaults.standard.set(hashed, forKey: passwordKey)
    }

    static func storedHashedPassword() -> String? {
        UserDefaults.standard.string(forKey: passwordKey)
    }
}

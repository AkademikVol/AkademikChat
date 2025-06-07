import Foundation

struct User: Identifiable {
    let id = UUID()
    let nickname: String
    let userId: String
}
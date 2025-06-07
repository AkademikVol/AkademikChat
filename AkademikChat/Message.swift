import Foundation

struct Message: Identifiable, Codable {
    let id: UUID
    let from: String
    let text: String
    let isMe: Bool

    init(id: UUID = UUID(), from: String, text: String, isMe: Bool) {
        self.id = id
        self.from = from
        self.text = text
        self.isMe = isMe
    }
}
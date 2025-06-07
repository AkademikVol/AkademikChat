import Foundation
import Network

class ChatSession: ObservableObject {
    static let shared = ChatSession()
    @Published var username: String = ""
    @Published var connection: NWConnection?

    private init() {}

    func configure(username: String, connection: NWConnection) {
        self.username = username
        self.connection = connection
    }
}
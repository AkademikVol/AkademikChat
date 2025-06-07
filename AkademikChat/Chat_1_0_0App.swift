import SwiftUI

@main
struct Chat_1_0_0App: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var openRecipient: String? = nil

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                ContentView(onOpenChat: { id in
                    openRecipient = id
                })
                .navigationDestination(
                    unwrapping: $openRecipient
                ) { recipientId in
                    ChatView(
                        username: ChatSession.shared.username,
                        connection: ChatSession.shared.connection!,
                        recipientId: recipientId,
                        recipientNickname: recipientId
                    )
                }
                .onReceive(
                    NotificationCenter.default.publisher(for: .openChat)
                ) { notif in
                    if let from = notif.object as? String {
                        openRecipient = from
                    }
                }
            }
        }
    }
}
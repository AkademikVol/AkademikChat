import SwiftUI
import Network
import UserNotifications

struct ChatView: View {
    let username: String
    let connection: NWConnection
    let recipientId: String
    let recipientNickname: String

    @State private var messages: [Message] = []
    @State private var inputText: String = ""

    private var historyURL: URL {
        FileManager.default
          .urls(for:.documentDirectory,in:.userDomainMask)[0]
          .appendingPathComponent("\(username)_\(recipientId)_history.json")
    }

    var body: some View {
        VStack {
            ScrollViewReader { proxy in
                ScrollView {
                    ForEach(messages) { msg in
                        MessageBubbleView(message: msg)
                            .id(msg.id)
                    }
                }
                .onChange(of: messages.count) { _ in
                    if let last = messages.last?.id {
                        proxy.scrollTo(last, anchor: .bottom)
                    }
                }
            }
            HStack {
                TextField("Повідомлення...", text: $inputText)
                    .textFieldStyle(.roundedBorder)
                Button(action: sendMessage) {
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(.white)
                        .padding(10)
                        .background(Color.blue)
                        .clipShape(Circle())
                }
            }
            .padding()
        }
        .navigationTitle(recipientNickname)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadLocalHistory()
            let offReq = ["action":"fetch_offline"]
            if let jd = try? JSONSerialization.data(withJSONObject: offReq) {
                connection.send(content: jd + Data("\n".utf8)) { _ in
                    listenForMessages()
                }
            } else {
                listenForMessages()
            }
        }
    }

    private func loadLocalHistory() {
        guard let d = try? Data(contentsOf: historyURL),
              let arr = try? JSONDecoder().decode([Message].self, from: d)
        else { return }
        messages = arr
    }
    private func saveLocalHistory() {
        if let d = try? JSONEncoder().encode(messages) {
            try? d.write(to: historyURL)
        }
    }

    func sendMessage() {
        guard !inputText.isEmpty else { return }
        let t = inputText; inputText = ""
        let pkt = ["action":"private_message","to":recipientId,"text":t]
        if let jd = try? JSONSerialization.data(withJSONObject: pkt) {
            connection.send(content: jd + Data("\n".utf8)) { _ in }
        }
        let ts = DateFormatter.localizedString(from:Date(),dateStyle:.none,timeStyle:.short)
        let msg = Message(from: username, text: "[\(ts)] \(t)", isMe: true)
        messages.append(msg); saveLocalHistory()
    }

    func listenForMessages() {
        connection.receive(minimumIncompleteLength:1, maximumLength:8192) { data, _, _, _ in
            guard let d = data, let s = String(data: d, encoding: .utf8) else {
                listenForMessages(); return
            }
            for line in s.split(separator:"\n").map(String.init) {
                if let pd = line.data(using: .utf8),
                   let obj = try? JSONSerialization.jsonObject(with: pd) as? [String:String],
                   let fr = obj["from"], let txt = obj["text"] {
                    let time = obj["time"] ?? ""
                    let disp = time.isEmpty ? txt : "[\(time)] \(txt)"
                    let inc = Message(from: fr, text: disp, isMe: false)
                    DispatchQueue.main.async {
                        messages.append(inc)
                        saveLocalHistory()
                        if UIApplication.shared.applicationState != .active {
                            let content = UNMutableNotificationContent()
                            content.title = "Нове повідомлення від \(fr)"
                            content.body = txt
                            content.sound = .default
                            UNUserNotificationCenter.current().add(
                                UNNotificationRequest(
                                    identifier: UUID().uuidString,
                                    content: content,
                                    trigger: nil
                                )
                            )
                        }
                    }
                }
            }
            listenForMessages()
        }
    }
}
import SwiftUI
import Network

struct ContentView: View {
    var onOpenChat: (String) -> Void

    @State private var ip = "192.168.1.238"
    @State private var port = "1076"
    @State private var username = ""
    @State private var password = ""
    @State private var status = ""
    @State private var isAuth = false

    var body: some View {
        NavigationStack {
            if isAuth, let connection = ChatSession.shared.connection {
                ChatListView(username: username, connection: connection)
            } else {
                VStack(spacing: 20) {
                    Text("AkademikChat").font(.largeTitle).bold()

                    TextField("IP сервера", text: $ip)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.decimalPad)

                    TextField("Порт", text: $port)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.numberPad)

                    TextField("Логін", text: $username)
                        .textFieldStyle(.roundedBorder)

                    SecureField("Пароль", text: $password)
                        .textFieldStyle(.roundedBorder)

                    Button("Увійти") {
                        connect()
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)

                    Text(status).foregroundColor(.red)
                }
                .padding()
            }
        }
    }

    func connect() {
        guard let p = UInt16(port) else {
            status = "Невірний порт"
            return
        }
        let c = NWConnection(host: ip, port: p, using: .tcp)
        ChatSession.shared.configure(username: username, connection: c)

        c.stateUpdateHandler = { newState in
            switch newState {
            case .ready:
                authenticate(connection: c)
            case .failed(let error):
                DispatchQueue.main.async {
                    status = "Помилка: \(error.localizedDescription)"
                }
            default: break
            }
        }
        c.start(queue: .global())
    }

    func authenticate(connection c: NWConnection) {
        let req = "VERSION_REQUEST\n".data(using: .utf8)!
        c.send(content: req) { _ in
            c.receive(minimumIncompleteLength: 1, maximumLength: 1024) { data, _, _, _ in
                if let d = data,
                   String(data: d, encoding: .utf8)?
                    .trimmingCharacters(in: .whitespacesAndNewlines) == "1.0.0" {
                    let creds = ["username": username, "password": password]
                    let jd = try! JSONEncoder().encode(creds) + Data("\n".utf8)
                    c.send(content: jd) { _ in
                        c.receive(minimumIncompleteLength: 1, maximumLength: 1024) { resp, _, _, _ in
                            if let r = resp,
                               String(data: r, encoding: .utf8)?
                                .contains("AUTH_SUCCESS") == true {
                                DispatchQueue.main.async { isAuth = true }
                            } else {
                                DispatchQueue.main.async { status = "Невірні дані" }
                                c.cancel()
                            }
                        }
                    }
                } else {
                    DispatchQueue.main.async { status = "Несумісна версія" }
                    c.cancel()
                }
            }
        }
    }
}
import SwiftUI
import Network

struct ChatListView: View {
    let username: String
    let connection: NWConnection

    @State private var allUsers: [User] = []
    @State private var threads: [User] = []
    @State private var search = ""
    @State private var selected: User? = nil

    var body: some View {
        VStack {
            TextField("Пошук...", text: $search)
                .padding(8)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .padding(.horizontal)
                .onChange(of: search) { new in
                    new.isEmpty ? loadThreads() : searchUsers(query: new)
                }

            List {
                if !threads.isEmpty {
                    Section("Чати") {
                        ForEach(threads) { u in
                            Button(u.nickname) { selected = u }
                        }
                    }
                }
                if !search.isEmpty {
                    Section("Результати") {
                        ForEach(allUsers) { u in
                            Button(u.nickname) { selected = u }
                        }
                    }
                }
            }
            .listStyle(.plain)
            .navigationTitle("Чати")
            .navigationDestination(
                unwrapping: Binding(
                    get: { selected?.userId },
                    set: { _ in selected = nil }
                )
            ) { rid in
                let user = (allUsers.first { $0.userId == rid }
                            ?? User(nickname: rid, userId: rid))
                ChatView(
                    username: username,
                    connection: connection,
                    recipientId: user.userId,
                    recipientNickname: user.nickname
                )
            }
        }
        .onAppear {
            fetchAllUsers()
            loadThreads()
        }
    }

    private func fetchAllUsers() {
        let req = ["action":"search_user","query":""]
        let data = try! JSONSerialization.data(withJSONObject: req) + Data("\n".utf8)
        connection.send(content: data) { _ in
            connection.receive(minimumIncompleteLength:1, maximumLength:4096) { resp, _, _, _ in
                if let d = resp,
                   let json = try? JSONSerialization.jsonObject(with: d) as? [String:Any],
                   let us = json["users"] as? [[String:String]] {
                    let parsed = us.compactMap { dict in
                        dict["userId"].map { User(nickname: dict["nickname"] ?? $0, userId: $0) }
                    }
                    DispatchQueue.main.async {
                        allUsers = parsed
                        loadThreads()
                    }
                }
            }
        }
    }

    private func searchUsers(query: String) {
        let req = ["action":"search_user","query":query]
        let data = try! JSONSerialization.data(withJSONObject: req) + Data("\n".utf8)
        connection.send(content: data) { _ in
            connection.receive(minimumIncompleteLength:1, maximumLength:4096) { resp, _, _, _ in
                if let d = resp,
                   let json = try? JSONSerialization.jsonObject(with: d) as? [String:Any],
                   let us = json["users"] as? [[String:String]] {
                    let parsed = us.compactMap { dict in
                        dict["userId"].map { User(nickname: dict["nickname"] ?? $0, userId: $0) }
                    }
                    DispatchQueue.main.async { allUsers = parsed }
                }
            }
        }
    }

    private func loadThreads() {
        let docs = FileManager.default.urls(for:.documentDirectory,in:.userDomainMask)[0]
        let files = (try? FileManager.default.contentsOfDirectory(at: docs, includingPropertiesForKeys: nil)) ?? []
        threads = files.compactMap { url in
            let name = url.lastPathComponent
            guard name.hasSuffix("_history.json") else { return nil }
            let parts = name.split(separator: "_")
            guard parts.count >= 3, parts[0] == username else { return nil }
            let rid = String(parts[1])
            return allUsers.first(where: { $0.userId == rid })
                ?? User(nickname: rid, userId: rid)
        }
    }
}
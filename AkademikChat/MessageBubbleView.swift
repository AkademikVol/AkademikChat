import SwiftUI

struct MessageBubbleView: View {
    let message: Message

    var body: some View {
        HStack {
            if message.isMe { Spacer() }
            Text(message.text)
                .padding()
                .background(message.isMe ? Color.blue : Color(.systemGray5))
                .foregroundColor(message.isMe ? .white : .black)
                .cornerRadius(16)
                .frame(maxWidth: 250, alignment: message.isMe ? .trailing : .leading)
                .padding(message.isMe ? .leading : .trailing, 40)
            if !message.isMe { Spacer() }
        }
        .padding(.vertical, 4)
    }
}
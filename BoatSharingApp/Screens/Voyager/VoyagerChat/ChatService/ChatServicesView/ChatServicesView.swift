// ChatServicesView.swift
import SwiftUI

struct ChatServicesView: View {
    let chatId: String
    let currentUserId: String
    let receiver: VoyagerUser

    @State private var messages: [ChatServicesModel] = []
    @State private var newMessage: String = ""
    @StateObject private var chatService: ChatServiceViewModel

    init(
        dependencies: AppDependencies = .live,
        chatId: String,
        currentUserId: String,
        receiver: VoyagerUser
    ) {
        self.chatId = chatId
        self.currentUserId = currentUserId
        self.receiver = receiver
        _chatService = StateObject(wrappedValue: ChatServiceViewModel(apiClient: dependencies.apiClient))
    }

    var body: some View {
        VStack {
            // Custom top bar with back button and receiver name
            HStack {
                Button(action: {
                    // Handle back action
                }) {
                    Image(systemName: "arrow.backward")
                        .foregroundColor(.black)
                }
                Spacer()
                Text("Chat with \(receiver.firstName)")
                    .font(.headline)
                    .foregroundColor(.black)
                Spacer()
                Spacer().frame(width: 30) // Spacer to balance layout
            }
            .padding()

            List(messages) { message in
                HStack {
                    if message.senderId == currentUserId {
                        Spacer()
                        VStack(alignment: .trailing) {
                            Text(message.text)
                                .padding(10)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                            HStack {
                                Text("05:24 PM") // Replace with dynamic timestamp if available
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                    .font(.caption)
                            }
                        }
                    } else {
                        VStack(alignment: .leading) {
                            Text(message.text)
                                .padding(10)
                                .background(Color.gray.opacity(0.2))
                                .foregroundColor(.primary)
                                .cornerRadius(10)
                            HStack {
                                Text("05:24 PM") // Replace with dynamic timestamp if available
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                    .font(.caption)
                            }
                        }
                        Spacer()
                    }
                }
                .padding(.vertical, 2)
            }
            .listStyle(PlainListStyle())

            HStack {
                TextField("Type a message", text: $newMessage)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(height: 60) // Increased height
                    .padding(.horizontal, 15)
                    .background(Color(.systemGray5)) // Light color
                    .cornerRadius(10) // Corner radius
                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2) // Shadow effect
                Button(action: sendMessage) {
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(.blue)
                        .padding(15) // Increased padding for larger size
                        .frame(width: 60, height: 60) // Increased frame size
                }
            }
            .padding()
           
        }
        .navigationTitle("Chat with \(receiver.firstName)") // Kept for reference, will be hidden
        .navigationBarHidden(true) // Hide the navigation bar
        .onAppear {
            chatService.send(.listenForMessages(chatId: chatId, completion: { fetchedMessages in
                self.messages = fetchedMessages
            }))
        }
    }

    private func sendMessage() {
        guard !newMessage.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        chatService.send(.sendMessage(chatId: chatId, senderId: currentUserId, text: newMessage))
        newMessage = ""
    }
}

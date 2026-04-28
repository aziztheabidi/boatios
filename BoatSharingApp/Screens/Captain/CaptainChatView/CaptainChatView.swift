import SwiftUI

struct CaptainChatView: View {
    let chatId: String
    let currentUserId: String
    let receiver: String

    @State private var messages: [ChatServicesModel] = []
    @State private var newMessage: String = ""
    @StateObject private var chatService: ChatServiceViewModel

    @Environment(\.dismiss) private var dismiss

    init(
        dependencies: AppDependencies = .live,
        chatId: String,
        currentUserId: String,
        receiver: String
    ) {
        self.chatId = chatId
        self.currentUserId = currentUserId
        self.receiver = receiver
        _chatService = StateObject(wrappedValue: ChatServiceViewModel(networkRepository: dependencies.networkRepository))
    }

    @State private var showFlagAlert = false
    @State private var showResultAlert = false
    @State private var resultMessage = ""
    @State private var selectedMessage: ChatServicesModel?
    @State private var awaitingFlagResult = false

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Top Bar
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "arrow.backward")
                            .foregroundColor(.black)
                            .padding(10)
                    }
                    Spacer()
                    Text("Chat with Voyager")
                        .font(.headline)
                        .foregroundColor(.black)
                        .padding(.leading, -15)
                    Spacer()
                }
                
                .padding(.top, 0)
                .background(Color.white)
                .shadow(color: Color.black.opacity(0.1), radius: 4, y: 2)

                // Messages List
                List(messages) { message in
                    HStack {
                        if message.senderId == currentUserId {
                            Spacer()
                            Text(message.text)
                                .padding(10)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        } else {
                            Text(message.text)
                                .padding(10)
                                .background(Color.gray.opacity(0.2))
                                .foregroundColor(.primary)
                                .cornerRadius(10)
                                .onLongPressGesture {
                                    // Only allow tagging receiver messages
                                    selectedMessage = message
                                    showFlagAlert = true
                                }
                            Spacer()
                        }
                    }
                    .padding(.vertical, 2)
                }
                .listStyle(PlainListStyle())

                // Message Input
                HStack {
                    TextField("Type a message", text: $newMessage)
                        .textFieldStyle(RoundedBorderTextFieldStyle())

                    Button(action: sendMessage) {
                        Image(systemName: "paperplane.fill")
                            .foregroundColor(.blue)
                            .padding(10)
                    }
                }
                .padding()
            }

            // Loader overlay
            if chatService.isTagLoading {
                Color.black.opacity(0.3).ignoresSafeArea()
                ProgressView("Flagging message...")
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
            }
        }
        .task(id: chatId) {
            for await fetchedMessages in chatService.messagesStream(chatId: chatId) {
                messages = fetchedMessages
            }
        }
        .alert("Do you want to add flag on this message?", isPresented: $showFlagAlert) {
            Button("Yes", role: .destructive) {
                if let message = selectedMessage {
                    flagMessage(message)
                }
            }
            Button("No", role: .cancel) { }
        }
        .alert(resultMessage, isPresented: $showResultAlert) {
            Button("OK", role: .cancel) {}
        }
        .onChange(of: chatService.isTagLoading) { _, isLoading in
            guard awaitingFlagResult, !isLoading else { return }
            awaitingFlagResult = false
            if let errorMessage = chatService.TagErrorMessage {
                resultMessage = "Failed: \(errorMessage)"
            } else {
                resultMessage = "Flag submitted successfully."
            }
            showResultAlert = true
        }
    }

    private func sendMessage() {
        guard !newMessage.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        chatService.send(.sendMessage(chatId: chatId, senderId: currentUserId, text: newMessage))
        newMessage = ""
    }

    private func flagMessage(_ message: ChatServicesModel) {
        // Call API to tag the receiver message
        awaitingFlagResult = true
        chatService.send(.tagMessage(voyagerId: receiver, description: message.text))
    }
}




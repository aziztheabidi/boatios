//  Untitled.swift
//  BoatSharingApp
//
//  Created by Mac User on 25/05/2025.
//

import FirebaseFirestore
import Foundation
import SwiftUI

@MainActor
class ChatServiceViewModel: ObservableObject {
    struct State {
        let route: Route?
        let tagErrorMessage: String?
        let isTagLoading: Bool
    }
    enum Action {
        case onAppear
        case onDisappear
        case sendMessage(chatId: String, senderId: String, text: String)
        case tagMessage(voyagerId: String, description: String)
    }
    enum Route { case none }
    @Published var route: Route?
    var state: State {
        State(route: route, tagErrorMessage: TagErrorMessage, isTagLoading: isTagLoading)
    }
    func send(_ action: Action) {
        switch action {
        case .onAppear, .onDisappear:
            break
        case .sendMessage(let chatId, let senderId, let text):
            sendMessage(chatId: chatId, senderId: senderId, text: text)
        case .tagMessage(let voyagerId, let description):
            TagMessageFromChat(VoyagerID: voyagerId, description: description)
        }
    }
    private let networkRepository: AppNetworkRepositoryProtocol

    init(networkRepository: AppNetworkRepositoryProtocol) {
        self.networkRepository = networkRepository
    }

    private let db = Firestore.firestore()
    @Published var TagErrorMessage: String?

    @Published var isTagLoading: Bool = false

    /// Live message list for `chatId`; terminates (and removes the Firestore listener) when the consuming `Task` is cancelled.
    nonisolated func messagesStream(chatId: String) -> AsyncStream<[ChatServicesModel]> {
        let db = Firestore.firestore()
        return AsyncStream { continuation in
            let registration = db.collection("chats").document(chatId).collection("messages")
                .order(by: "timestamp")
                .addSnapshotListener { snapshot, _ in
                    guard let documents = snapshot?.documents else {
                        continuation.yield([])
                        return
                    }

                    let messages = documents.compactMap { doc -> ChatServicesModel? in
                        let data = doc.data()
                        guard let text = data["text"] as? String,
                              let senderId = data["senderId"] as? String,
                              let timestamp = data["timestamp"] as? Timestamp else { return nil }

                        return ChatServicesModel(id: doc.documentID, text: text, senderId: senderId, timestamp: timestamp.dateValue())
                    }

                    continuation.yield(messages)
                }
            continuation.onTermination = { @Sendable _ in
                registration.remove()
            }
        }
    }

    func sendMessage(chatId: String, senderId: String, text: String) {
        let messageRef = db.collection("chats").document(chatId).collection("messages").document()
        messageRef.setData([
            "text": text,
            "senderId": senderId,
            "timestamp": FieldValue.serverTimestamp()
        ])
    }
    static func getOrCreateChatId(currentUserId: String, otherUserId: String) -> String {
        currentUserId < otherUserId
            ? "\(currentUserId)_\(otherUserId)"
            : "\(otherUserId)_\(currentUserId)"
    }

    func TagMessageFromChat(VoyagerID: String, description: String) {
        isTagLoading = true
        TagErrorMessage = nil
        let parameters: [String: Any] = ["VoyageId": VoyagerID, "Description": description]
        Task { @MainActor in
            do {
                _ = try await networkRepository.voyager_complain(parameters: parameters)
                self.isTagLoading = false
            } catch {
                self.isTagLoading = false
                self.TagErrorMessage = error.localizedDescription
            }
        }
    }
}



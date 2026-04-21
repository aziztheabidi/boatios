
//  Untitled.swift
//  BoatSharingApp
//
//  Created by Mac User on 25/05/2025.
//

import FirebaseFirestore
import Foundation

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
        case listenForMessages(chatId: String, completion: ([ChatServicesModel]) -> Void)
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
        case .listenForMessages(let chatId, let completion):
            listenForMessages(chatId: chatId, completion: completion)
        case .tagMessage(let voyagerId, let description):
            TagMessageFromChat(VoyagerID: voyagerId, description: description)
        }
    }
    private let apiClient: APIClientProtocol

    init(apiClient: APIClientProtocol) {
        self.apiClient = apiClient
    }

    private let db = Firestore.firestore()
    @Published var TagErrorMessage: String?

    @Published var isTagLoading: Bool = false
    func getOrCreateChatId(for user1: String, and user2: String, completion: @escaping (String?) -> Void) {
        let chatUsers = [user1, user2].sorted()
        let chatQuery = db.collection("chats")
            .whereField("users", isEqualTo: chatUsers)

        chatQuery.getDocuments { snapshot, error in
            if let error = error {
                completion(nil)
                return
            }

            if let doc = snapshot?.documents.first {
                completion(doc.documentID)
            } else {
                let newChatRef = self.db.collection("chats").document()
                newChatRef.setData([
                    "users": chatUsers,
                    "createdAt": FieldValue.serverTimestamp()
                ]) { err in
                    if let err = err {
                        completion(nil)
                    } else {
                        completion(newChatRef.documentID)
                    }
                }
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
           return currentUserId < otherUserId
               ? "\(currentUserId)_\(otherUserId)"
               : "\(otherUserId)_\(currentUserId)"
       }
    func listenForMessages(chatId: String, completion: @escaping ([ChatServicesModel]) -> Void) {
        db.collection("chats").document(chatId).collection("messages")
            .order(by: "timestamp")
            .addSnapshotListener { snapshot, error in
                guard let documents = snapshot?.documents else {
                    return
                }

                let messages = documents.compactMap { doc -> ChatServicesModel? in
                    let data = doc.data()
                    guard let text = data["text"] as? String,
                          let senderId = data["senderId"] as? String,
                          let timestamp = data["timestamp"] as? Timestamp else { return nil }

                    return ChatServicesModel(id: doc.documentID, text: text, senderId: senderId, timestamp: timestamp.dateValue())
                }

                completion(messages)
            }
    }
    
    
    func TagMessageFromChat(VoyagerID: String, description: String) {
        isTagLoading = true
        TagErrorMessage = nil
        let parameters: [String: Any] = ["VoyageId": VoyagerID, "Description": description]
        Task {
            do {
                let _: TagChatMessage = try await apiClient.request(
                    endpoint: "/Voyager/Complain",
                    method: HTTPMethod.post,
                    parameters: parameters,
                    requiresAuth: true
                )
                self.isTagLoading = false
            } catch {
                self.isTagLoading = false
                self.TagErrorMessage = error.localizedDescription
            }
        }
    }

    
    
    
    
    
    
    
}


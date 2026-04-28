import SwiftUI

struct VoyagerChatView: View {
    @StateObject private var viewModel: SponsorRelationshipViewModel
    @Environment(\.presentationMode) var presentationMode

    init(dependencies: AppDependencies = .live) {
        _viewModel = StateObject(wrappedValue: SponsorRelationshipViewModel(
            networkRepository: dependencies.networkRepository,
            sessionPreferences: dependencies.sessionPreferences
        ))
    }
    @State private var selectedTab: Tab = .followed
    @State private var selectedUser: VoyagerUser? = nil
    @State private var navigateToChat = false
    @State private var searchText: String = ""

    enum Tab: String, CaseIterable {
        case followed = "Followed"
        case all = "All"
    }

    var body: some View {
            VStack(spacing: 0) {
                // Top bar replaced with search bar
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "arrow.backward")
                            .foregroundColor(.black)
                    }
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        TextField("Search Voyagers", text: $searchText)
                            .textFieldStyle(PlainTextFieldStyle())
                            .foregroundColor(.black)
                        if !searchText.isEmpty {
                            Button(action: {
                                searchText = ""
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 10)
                    .background(Color(.systemGray6))
                    .cornerRadius(20)
                    Spacer()
                    Spacer().frame(width: 30) // Spacer to balance chevron width
                }
                .padding()

                // Segmented control
                HStack(spacing: 0) {
                    Button(action: {
                        selectedTab = .followed
                        searchText = "" // Empty search text when switching categories
                    }) {
                        Text("Followed")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(selectedTab == .followed ? .white : .blue)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(selectedTab == .followed ? Color.blue : Color.white)
                    }

                    Button(action: {
                        selectedTab = .all
                        searchText = "" // Empty search text when switching categories
                    }) {
                        Text("All")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(selectedTab == .all ? .white : .blue)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(selectedTab == .all ? Color.blue : Color.white)
                    }
                }
                .background(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.gray, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .padding(.horizontal, 20)
                .padding(.bottom, 8)

                // Content
                // Content

                
                
                // Content
                if viewModel.isLoading {
                    Spacer()
                    ProgressView()
                    Spacer()
                } else {
                    VStack(spacing: 0) {

                        if filteredUsers.isEmpty {
                            // Show empty list message
                            Text("List Empty")
                                .foregroundColor(.gray.opacity(0.6))
                                .font(.system(size: 18, weight: .medium))
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.top, 40)

                            Spacer()
                        } else {
                            List(filteredUsers) { user in
                                Button(action: {
                                    selectedUser = user
                                    navigateToChat = true
                                }) {
                                    HStack {
                                        Text(String(user.firstName.prefix(1)))
                                            .font(.title3)
                                            .foregroundColor(.black)
                                            .frame(width: 40, height: 40)
                                            .background(Color.gray.opacity(0.2))
                                            .clipShape(Circle())

                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("\(user.firstName) \(user.lastName)")
                                                .font(.headline)
                                            Text("Let's chat")
                                                .font(.subheadline)
                                                .foregroundColor(.gray)
                                        }
                                        Spacer()

                                        if selectedTab == .followed {
                                            Text("Message")
                                                .font(.subheadline)
                                                .foregroundColor(.blue)
                                                .padding(.horizontal, 10)
                                                .padding(.vertical, 5)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 10)
                                                        .stroke(Color.blue, lineWidth: 2)
                                                )
                                        } else {
                                            Button(action: {
                                                viewModel.send(.follow(voyagerId: user.id))
                                            }) {
                                                Text("Follow")
                                                    .font(.subheadline)
                                                    .foregroundColor(.white)
                                                    .padding(.horizontal, 16)
                                                    .padding(.vertical, 8)
                                                    .background(Color.blue)
                                                    .cornerRadius(8)
                                            }
                                        }
                                    }
                                    .padding(.vertical, 5)
                                }
                            }
                            .listStyle(PlainListStyle())
                        }
                    }
                }

                
                
            }
            .navigationBarBackButtonHidden(true) // Hide the back button
                    .navigationBarHidden(true) // Hide the entire navigation bar
            .onAppear {
                viewModel.send(.onAppear)
            }
            .navigationDestination(isPresented: $navigateToChat) {
                if let selectedUser = selectedUser {
                    ChatServicesView(
                        chatId: ChatServiceViewModel.getOrCreateChatId(
                            currentUserId: viewModel.currentUserId,
                            otherUserId: selectedUser.id
                        ),
                        currentUserId: viewModel.currentUserId,
                        receiver: selectedUser
                    )
                    
                }
            }
            

            
        
    }

    private var displayedUsers: [VoyagerUser] {
        switch selectedTab {
        case .followed:
            return viewModel.followed
        case .all:
            return viewModel.followed + viewModel.unfollowed
        }
    }
    
    private var filteredUsers: [VoyagerUser] {
        if searchText.isEmpty {
            return displayedUsers
        } else {
            return displayedUsers.filter { user in
                let fullName = "\(user.firstName) \(user.lastName)".lowercased()
                return fullName.contains(searchText.lowercased())
            }
        }
    }
}

#Preview {
    VoyagerChatView()
}



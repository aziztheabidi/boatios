import SwiftUI

struct SponsorRelationshipView: View {
    @StateObject private var viewModel: SponsorRelationshipViewModel

    init(dependencies: AppDependencies = .live) {
        _viewModel = StateObject(wrappedValue: SponsorRelationshipViewModel(
            apiClient: dependencies.apiClient,
            sessionPreferences: dependencies.sessionPreferences
        ))
    }
    @State private var searchText: String = ""
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading) {
                // Top Title
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "arrow.backward")
                            .foregroundColor(.black)
                            .padding(.leading)
                    }

                    Spacer()

                    Text("Add Sponsors")
                        .font(.title3)
                        .foregroundColor(.black)
                        .padding(.leading, -30)

                    Spacer()
                }
                .padding(.vertical, 12)

                // Search Bar
                HStack {
                    TextField("Search sponsors here...", text: $searchText)
                        .padding(10)
                        .padding(.leading, 16)
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                        .overlay(
                            HStack {
                                Spacer()
                                Image(systemName: "magnifyingglass")
                                    .foregroundColor(.gray)
                                    .padding(.trailing, 10)
                            }
                        )
                }
                .padding(.horizontal)
                .padding(.top, 8)

                // Add Sponsors Text and Description
                VStack(alignment: .leading, spacing: 8) {
                    Text("Add Sponsors")
                        .font(.headline)
                        .foregroundColor(.black)
                        .padding(.horizontal)
                        .padding(.top, 8)

                    Text("Hey, sponsors are users you follow through the \"Connect with Voyagers\" option in the Menu. All registered voyagers are shown in the list.")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                }

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // Followed Section
                        if !viewModel.followed.isEmpty {
                            Text("Followed")
                                .font(.headline)
                                .padding(.horizontal)

                            ForEach(viewModel.followed.filter {
                                searchText.isEmpty || $0.firstName.localizedCaseInsensitiveContains(searchText)
                            }, id: \.userId) { user in
                                VoyagerRow(user: user, isFollowed: true) {
                                    viewModel.send(.unfollow(voyagerId: user.userId))
                                }
                            }
                        }
                        // Add extra spacing between followed and unfollowed
                        if !viewModel.followed.isEmpty && !viewModel.unfollowed.isEmpty {
                            Spacer().frame(height: 24)
                        }

                        // Unfollowed Section
                        if !viewModel.unfollowed.isEmpty {
                            Text("Unfollowed")
                                .font(.headline)
                                .padding(.horizontal)

                            ForEach(viewModel.unfollowed.filter {
                                searchText.isEmpty || $0.firstName.localizedCaseInsensitiveContains(searchText)
                            }, id: \.userId) { user in
                                VoyagerRow(user: user, isFollowed: false) {
                                    viewModel.send(.follow(voyagerId: user.userId))
                                }
                            }
                        }
                    }
                    .padding(.top)
                }
            }
            .onAppear {
                viewModel.send(.onAppear)
            }
            .overlay {
                if viewModel.isLoading {
                    ZStack {
                        Color.black.opacity(0.4).ignoresSafeArea()
                        ProgressView("Please wait...")
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.black.opacity(0.7))
                            .cornerRadius(12)
                    }
                }
            }
        }
        .navigationBarBackButtonHidden(true)
    }
}

struct VoyagerRow: View {
    let user: VoyagerUser
    let isFollowed: Bool
    let onAction: () -> Void

    var body: some View {
        HStack {
            // Gray circle with first letter of first name
            ZStack {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 40, height: 40)
                Text(String(user.firstName.prefix(1)).uppercased())
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
            }
            .padding(.trailing, 8)

            VStack(alignment: .leading, spacing: 4) {
                Text(user.firstName)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }

            Spacer()

            // Checkbox for follow/unfollow
            Button(action: onAction) {
                Image(systemName: isFollowed ? "checkmark.square.fill" : "square")
                    .resizable()
                    .frame(width: 24, height: 24)
                    .foregroundColor(isFollowed ? .blue : .gray)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 6)
    }
}

struct SponsorRelationshipView_Previews: PreviewProvider {
    static var previews: some View {
        SponsorRelationshipView()
    }
}

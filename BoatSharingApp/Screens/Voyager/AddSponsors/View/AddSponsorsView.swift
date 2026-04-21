import SwiftUI

struct AddSponsorsView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var searchText: String = ""
    @StateObject private var viewModel: SponsorRelationshipViewModel
    @State private var selectedSponsorIDs: [String] = []
    @Binding var showAddSponsors: Bool
    var onSponsorsSelected: ([String]) -> Void

    init(
        dependencies: AppDependencies = .live,
        showAddSponsors: Binding<Bool>,
        onSponsorsSelected: @escaping ([String]) -> Void
    ) {
        _showAddSponsors = showAddSponsors
        self.onSponsorsSelected = onSponsorsSelected
        _viewModel = StateObject(wrappedValue: SponsorRelationshipViewModel(
            apiClient: dependencies.apiClient,
            sessionPreferences: dependencies.sessionPreferences
        ))
    }

    var filteredSponsors: [VoyagerUser] {
        if searchText.isEmpty {
            return viewModel.allSponsors
        } else {
            return viewModel.allSponsors.filter {
                $0.firstName.lowercased().contains(searchText.lowercased())
            }
        }
    }
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "arrow.backward")
                            .foregroundColor(.black)
                    }

                    Spacer()

                    Text("Add Sponsors")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.black)

                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top)

                // Search bar
                HStack {
                    TextField("Search", text: $searchText)
                        .padding(.vertical, 10)
                        .padding(.leading, 14)
                        .padding(.trailing, 36)
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                        .overlay(
                            HStack {
                                Spacer()
                                Image(systemName: "magnifyingglass")
                                    .foregroundColor(.gray)
                                    .padding(.trailing, 12)
                            }
                        )
                }
                .padding(.top, 20)
                .padding(.horizontal)
                .shadow(color: .gray.opacity(0.2), radius: 4, x: 0, y: 2)

                // Label
                HStack {
                    Text("Add Sponsors")
                        .font(.subheadline)
                        .foregroundColor(.black)
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 20)

                // List
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(filteredSponsors, id: \.userId) { sponsor in
                            HStack(spacing: 12) {
                                Image(systemName: "person.circle.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 30, height: 30)
                                    .foregroundColor(.blue)

                                Text(viewModel.myself?.userId == sponsor.userId ? "Myself" : sponsor.firstName)
                                    .font(.body)
                                    .foregroundColor(.black)

                                Spacer()

                                // Selection button
                                Button(action: {
                                    if selectedSponsorIDs.contains(sponsor.userId) {
                                        selectedSponsorIDs.removeAll { $0 == sponsor.userId }
                                    } else {
                                        selectedSponsorIDs.append(sponsor.userId)
                                    }
                                }) {
                                    Image(systemName: selectedSponsorIDs.contains(sponsor.userId) ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(selectedSponsorIDs.contains(sponsor.userId) ? .blue : .gray)
                                        .font(.system(size: 24))
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            .padding()
                            .background(Color.white)
                            .padding(.horizontal)

                            Divider()
                                .background(Color.gray.opacity(0.2))
                                .padding(.horizontal, 20)
                        }
                    }
                }
                .padding(.top, 10)

                // Add Button
                Button(action: {
                    onSponsorsSelected(selectedSponsorIDs)
                    presentationMode.wrappedValue.dismiss()
                    showAddSponsors = false
                }) {
                    Text("Add Sponsors")
                        .foregroundColor(.white)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                        .padding(.horizontal)
                        .padding(.bottom, 20)
                }
            }
            .onAppear {
                viewModel.send(.onAppear)
            }
            .onReceive(viewModel.$allSponsors) { sponsors in
                if let myId = viewModel.myself?.userId,
                   !selectedSponsorIDs.contains(myId) {
                    selectedSponsorIDs.append(myId)
                }
            }
            .background(Color.white.ignoresSafeArea())
            .navigationBarHidden(true)
        }
    }
}


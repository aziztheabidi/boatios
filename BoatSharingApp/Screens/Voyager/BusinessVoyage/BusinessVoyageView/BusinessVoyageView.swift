import SwiftUI

struct BusinessVoyageView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var viewModel: BusinessVoyageViewModel
    @State private var selectedTab: Tab = .followed
    @State private var selectedBusiness: BusinessRelationship?
    @State private var navigateToDetail = false

    private let imageBasePath = AppConfiguration.API.imageBaseURL

    enum Tab {
        case followed
        case unfollowed
    }

    init(dependencies: AppDependencies = .live) {
        _viewModel = StateObject(wrappedValue: BusinessVoyageViewModel(apiClient: dependencies.apiClient))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "arrow.backward")
                            .foregroundColor(Color.black)
                            .padding()
                    }

                    Spacer()

                    Text("Businesses")
                        .font(.title2)
                        .bold()

                    Spacer()

                    Spacer().frame(width: 44) // Placeholder
                }

                // Toggle Tabs
                HStack(spacing: 0) {
                    Button(action: {
                        selectedTab = .followed
                    }) {
                        Text("Followed")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(selectedTab == .followed ? .white : .AppColor)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(selectedTab == .followed ? Color.AppColor : Color.white)
                    }

                    Button(action: {
                        selectedTab = .unfollowed
                    }) {
                        Text("All")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(selectedTab == .unfollowed ? .white : .AppColor)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(selectedTab == .unfollowed ? Color.AppColor : Color.white)
                    }
                }
                .background(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.blue, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .padding(.horizontal, 20)
                .padding(.bottom, 8)

                Divider()

                // Business List
                ScrollView {
                    LazyVStack(spacing: 12) {
                        if viewModel.isLoading {
                            ProgressView("Loading...")
                                .padding()
                        } else {
                            let dataList = selectedTab == .followed ? viewModel.followedBusinesses : viewModel.unfollowedBusinesses

                            if dataList.isEmpty {
                                Text("No Data Found")
                                    .foregroundColor(.gray)
                                    .padding()
                            } else {
                                ForEach(dataList) { business in
                                    BusinessCardView(
                                        business: business,
                                        imageBasePath: imageBasePath,
                                        isFollowed: selectedTab == .followed,
                                        viewModel: viewModel,
                                        selectedTab: selectedTab,
                                        onDetailTap: {
                                            selectedBusiness = business
                                            navigateToDetail = true
                                        }
                                    )
                                }
                            }
                        }
                    }
                    .padding()
                }

                NavigationLink(
                    destination: selectedBusiness.map {
                        BusinessVoyageDetailView(business: $0, imageBasePath: imageBasePath)
                    },
                    isActive: $navigateToDetail,
                    label: {
                        EmptyView()
                    }
                )
                .hidden()
            }
            .onAppear {
                viewModel.send(.onAppear)
            }
            .navigationBarBackButtonHidden(true)
        }
    }
}

struct BusinessCardView: View {
    let business: BusinessRelationship
    let imageBasePath: String
    let isFollowed: Bool
    @ObservedObject var viewModel: BusinessVoyageViewModel
    let selectedTab: BusinessVoyageView.Tab
    let onDetailTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                if business.logoPath.isEmpty || URL(string: imageBasePath + business.logoPath.replacingOccurrences(of: "\\", with: "/")) == nil {
                    Image("b_logo")
                        .resizable()
                        .frame(width: 60, height: 60)
                        .cornerRadius(10)
                } else {
                    AsyncImage(url: URL(string: imageBasePath + business.logoPath.replacingOccurrences(of: "\\", with: "/"))) { image in
                        image.resizable()
                    } placeholder: {
                        Image("b_logo")
                            .resizable()
                            .frame(width: 60, height: 60)
                            .cornerRadius(10)
                    }
                    .frame(width: 60, height: 60)
                    .cornerRadius(8)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(business.name)
                        .font(.headline)

                    Text(business.businessType.capitalized)
                        .font(.subheadline)
                        .foregroundColor(.gray)

                    if !business.description.isEmpty {
                        Text(business.description)
                            .font(.footnote)
                            .foregroundColor(.secondary)
                            .padding(.top, 4)
                    }
                }

                Spacer()
            }

            Spacer()
        }
        .padding()
        .frame(minHeight: 110)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.blue, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        .onTapGesture {
            onDetailTap()
        }
    }
}

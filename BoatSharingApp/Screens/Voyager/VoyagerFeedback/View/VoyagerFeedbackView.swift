import SwiftUI

struct VoyagerFeedbackView: View {
    let voyageId: String
    let feedbackSource: String
    @StateObject private var viewModel: VoyagerFeedbackViewModel

    init(dependencies: AppDependencies = .live, voyageId: String, feedbackSource: String) {
        self.voyageId = voyageId
        self.feedbackSource = feedbackSource
        _viewModel = StateObject(wrappedValue: VoyagerFeedbackViewModel(networkRepository: dependencies.networkRepository))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                VStack(spacing: 20) {
                    Spacer()
                    Text("Your Voyage has been ended!")
                        .font(.title)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                    
                    Text("Thank you for your ride, give reviews to the captain so that next voyage can get benefitted.")
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    // Rating with Docker images
                    HStack(spacing: 15) {
                        ForEach(0..<5) { index in
                            Image("Docker")
                                .resizable()
                                .frame(width: 30, height: 30)
                                .background(
                                    Circle()
                                        .fill((viewModel.state.selectedRating ?? -1) >= index ? Color.blue : Color.clear)
                                        .frame(width: 40, height: 40)
                                )
                                .onTapGesture {
                                    viewModel.send(.selectRating(index))
                                }
                        }
                    }
                    .padding(.horizontal)
                    
                    // Remarks Text Box
                    TextEditor(
                        text: Binding(
                            get: { viewModel.state.remarks },
                            set: { viewModel.send(.updateRemarks($0)) }
                        )
                    )
                        .frame(height: 100)
                        .padding()
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.gray.opacity(0.4), lineWidth: 1)
                        )
                        .padding(.horizontal)
                    
                    // Buttons
                    HStack(spacing: 20) {
                        Button(action: {
                            viewModel.send(.navigateLater(.init(from: feedbackSource)))
                        }) {
                            Text("Later")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.white)
                                .foregroundColor(.blue)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.blue, lineWidth: 1)
                                )
                        }
                        

                        
                        
                        
                        Button {
                            UIApplication.shared.dismissKeyboard()
                            viewModel.send(.submit(voyageId: voyageId, source: .init(from: feedbackSource)))

                        } label: {
                            ZStack {
                                if viewModel.isFeedbackLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Text("Submit")
                                        .fontWeight(.bold)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        .disabled(viewModel.isFeedbackLoading)


                        
                        
                        
                        
                        
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                }
                .padding()
                
                // Toast Overlay
                if viewModel.state.isShowingToast {
                    Text(viewModel.state.toastMessage)
                        .padding()
                        .background(Color.black.opacity(0.7))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .transition(.scale)
                        .zIndex(1)
                }
            }
            .navigationDestination(item: $viewModel.stackDestination) { destination in
                switch destination {
                case .voyagerHome:
                    VoyagerHomeView()
                case .captainHome:
                    CaptainHomeVC()
                }
            }
            .navigationBarBackButtonHidden(true)
        }
    }
}

struct VoyagerFeedbackView_Previews: PreviewProvider {
    static var previews: some View {
        VoyagerFeedbackView(voyageId: "", feedbackSource: "")
            .previewLayout(.sizeThatFits)
            .padding()
    }
}



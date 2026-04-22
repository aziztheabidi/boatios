import SwiftUI
import PhotosUI

struct BusinessStepRegFour: View {
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var navigateToNext: Bool = false
    @StateObject private var viewModel: BusinessStepFourViewModel

    init(dependencies: AppDependencies = .live) {
        _viewModel = StateObject(wrappedValue: BusinessStepFourViewModel(
            preferences: dependencies.preferences,
            sessionPreferences: dependencies.sessionPreferences,
            routingNotifier: dependencies.routingNotifier,
            mediaUploader: dependencies.businessSaveMediaUploader
        ))
    }
    @State private var showToast: Bool = false
    @State private var toastMessage: String = ""
    @State private var selectedBusinessItems: [PhotosPickerItem] = []
    @State private var selectedBusinessImages: [UIImage] = []

    var isImageSelected: Bool {
        selectedImage != nil
    }

    var canAddMoreImages: Bool {
        selectedBusinessImages.count < 6
    }

    var body: some View {
        NavigationView {
            MainContentView(
                selectedItem: $selectedItem,
                selectedImage: $selectedImage,
                selectedBusinessItems: $selectedBusinessItems,
                selectedBusinessImages: $selectedBusinessImages,
                isImageSelected: isImageSelected,
                canAddMoreImages: canAddMoreImages,
                isLoading: viewModel.isLoading,
                registerAction: {
                    guard let image = selectedImage else { return }
                    let userId = viewModel.sessionUserId
                    guard !userId.isEmpty else { return }
                    viewModel.uploadBusinesslogo(UserID: userId, image: image, images: selectedBusinessImages)
                }
            )
            .overlay(ToastOverlayView(message: toastMessage, isPresented: $showToast))
            .background(NavigationHandlerView(navigateToNext: $navigateToNext))
            .onChange(of: selectedItem) { _, newValue in loadImage(from: newValue)  }
            .onChange(of: selectedBusinessItems) { _, newValue in loadBusinessImages(from: newValue)  }
            .onChange(of: viewModel.isSuccess) { _, newValue in handleSuccess(newValue)  }
            .onChange(of: viewModel.message) { _, newValue in handleMessage(newValue)  }
            .onChange(of: viewModel.shouldNavigateAfterSuccessDelay) { _, shouldNavigate in
                if shouldNavigate {
                    navigateToNext = true
                    viewModel.shouldNavigateAfterSuccessDelay = false
                }
            }
            .navigationBarBackButtonHidden(true)
        }
    }

    private func loadImage(from item: PhotosPickerItem?) {
        guard let item else { return }
        Task {
            if let data = try? await item.loadTransferable(type: Data.self),
               let uiImage = UIImage(data: data) {
                selectedImage = uiImage
            }
        }
    }

    private func loadBusinessImages(from items: [PhotosPickerItem]) {
        Task {
            var newImages: [UIImage] = []
            for item in items {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    newImages.append(uiImage)
                }
            }
            selectedBusinessImages = newImages
        }
    }

    private func handleSuccess(_ isSuccess: Bool) {
        if isSuccess {
            toastMessage = "Logo and images uploaded successfully!"
            showToast = true
            viewModel.scheduleNavigationAfterSuccessDelay()
        }
    }

    private func handleMessage(_ message: String) {
        if !viewModel.isSuccess && !message.isEmpty {
            toastMessage = message
            showToast = true
        }
    }
}

// MARK: - Main Content View

struct MainContentView: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var selectedItem: PhotosPickerItem?
    @Binding var selectedImage: UIImage?
    @Binding var selectedBusinessItems: [PhotosPickerItem]
    @Binding var selectedBusinessImages: [UIImage]
    let isImageSelected: Bool
    let canAddMoreImages: Bool
    let isLoading: Bool
    let registerAction: () -> Void

    var body: some View {
        VStack {
            BackButtonView(presentationMode: _presentationMode)
            ProgressBarView()
            AppLogoSectionView(
                selectedItem: $selectedItem,
                selectedImage: $selectedImage
            )
            BusinessImagesSectionView(
                selectedBusinessItems: $selectedBusinessItems,
                selectedBusinessImages: $selectedBusinessImages,
                canAddMoreImages: canAddMoreImages
            )
            RegisterButtonView(
                isImageSelected: isImageSelected,
                isLoading: isLoading,
                action: registerAction
            )
            Spacer()
        }
        .padding(.top)
    }
}

// MARK: - Navigation Handler

struct NavigationHandlerView: View {
    @Binding var navigateToNext: Bool

    var body: some View {
        NavigationLink(destination: DashboardVC(), isActive: $navigateToNext) {
            EmptyView()
        }
    }
}

// MARK: - Toast Overlay

struct ToastOverlayView: View {
    let message: String
    @Binding var isPresented: Bool

    var body: some View {
        ToastView(message: message, isPresented: $isPresented)
            .alignmentGuide(.bottom) { _ in 0 }
    }
}

// MARK: - Subviews

struct BackButtonView: View {
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        Button(action: {
            presentationMode.wrappedValue.dismiss()
        }) {
            Image(systemName: "arrow.backward")
                .foregroundColor(.black)
        }
        .padding(.leading)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct ProgressBarView: View {
    var body: some View {
        VStack {
            Text("Please Add Business Info 4/4")
                .padding(.top, -24)
            HStack(spacing: 10) {
                ForEach(0..<4, id: \.self) { _ in
                    Capsule()
                        .fill(Color.blue)
                        .frame(width: 35, height: 8)
                }
            }
            .padding()
        }
    }
}

struct AppLogoSectionView: View {
    @Binding var selectedItem: PhotosPickerItem?
    @Binding var selectedImage: UIImage?

    var body: some View {
        VStack {
            HStack {
                Text("App Logo")
                    .font(.subheadline)
                    .padding(.leading, 25)
                Spacer()
            }
            .padding(.horizontal)
            ImagePickerView(
                selectedItem: $selectedItem,
                selectedImage: $selectedImage,
                title: "Upload your business logo"
            )
        }
    }
}

struct BusinessImagesSectionView: View {
    @Binding var selectedBusinessItems: [PhotosPickerItem]
    @Binding var selectedBusinessImages: [UIImage]
    let canAddMoreImages: Bool

    var body: some View {
        VStack {
            HStack {
                Text("Business Images")
                    .font(.subheadline)
                    .padding(.leading, 25)
                Spacer()
            }
            .padding(.horizontal)
            .padding(.top, 20)
            MultiImagePickerView(
                selectedItems: $selectedBusinessItems,
                selectedImages: $selectedBusinessImages,
                canAddMoreImages: canAddMoreImages
            )
            if canAddMoreImages {
                Button(action: {}) {
                    Text("Add More")
                        .foregroundColor(.blue)
                        .padding(.top, 10)
                }
                .disabled(true)
            }
        }
    }
}

struct ImagePickerView: View {
    @Binding var selectedItem: PhotosPickerItem?
    @Binding var selectedImage: UIImage?
    let title: String

    var body: some View {
        VStack {
            Text(title)
                .foregroundColor(.black)
                .font(.subheadline)
                .padding(.top, 10)
            if let image = selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            } else {
                PhotosPicker(selection: $selectedItem, matching: .images, photoLibrary: .shared()) {
                    VStack {
                        Image(systemName: "photo.on.rectangle")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 50, height: 50)
                            .foregroundColor(.gray)
                            .padding()
                    }
                }
            }
        }
        .frame(width: 320, height: 200)
        .background(RoundedRectangle(cornerRadius: 10).stroke(Color.gray, lineWidth: 1))
        .padding(.top, 10)
    }
}

struct MultiImagePickerView: View {
    @Binding var selectedItems: [PhotosPickerItem]
    @Binding var selectedImages: [UIImage]
    let canAddMoreImages: Bool

    var body: some View {
        VStack(spacing: 8) {
            Text("Upload up to 6 business images")
                .foregroundColor(.black)
                .font(.subheadline)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(selectedImages, id: \.self) { image in
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 80, height: 80)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .clipped() // Ensure images don't exceed their frame
                    }
                    if canAddMoreImages {
                        PhotosPicker(selection: $selectedItems, maxSelectionCount: 6, matching: .images, photoLibrary: .shared()) {
                            Image(systemName: "plus.circle")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 50, height: 50)
                                .foregroundColor(.gray)
                                .padding(8)
                                .background(Circle().fill(Color.gray.opacity(0.1)))
                        }
                    }
                }
                .padding(.horizontal, 8)
            }
            .frame(height: 96) // Reduced height to fit content tightly
        }
        .frame(width: 320)
        .background(RoundedRectangle(cornerRadius: 10).stroke(Color.gray, lineWidth: 1))
        .clipped() // Ensure ScrollView content stays within bounds
        .padding(.top, 8)
    }
}

struct RegisterButtonView: View {
    let isImageSelected: Bool
    let isLoading: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            } else {
                Text("Register")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isImageSelected ? Color.blue : Color.gray.opacity(0.5))
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        .padding()
        .disabled(!isImageSelected || isLoading)
    }
}

struct BusinessRegFour_Previews: PreviewProvider {
    static var previews: some View {
        BusinessStepRegFour()
    }
}



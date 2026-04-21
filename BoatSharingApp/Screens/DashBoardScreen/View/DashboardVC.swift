import SwiftUI
import SDWebImageSwiftUI
import PhotosUI
import MapKit
import CoreLocation
import UIKit

struct DashboardVC: View {
    private let dependencies: AppDependencies
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var viewModel: DashboardVCViewModel
    @StateObject private var stepFourViewModel: BusinessStepFourViewModel
    @State private var isDockAdded: Bool = false

    init(dependencies: AppDependencies = .live) {
        self.dependencies = dependencies
        _viewModel = StateObject(wrappedValue: DashboardVCViewModel(businessRepository: dependencies.businessRepository))
        _stepFourViewModel = StateObject(wrappedValue: BusinessStepFourViewModel(preferences: dependencies.preferences, routingNotifier: dependencies.routingNotifier, mediaUploader: dependencies.businessSaveMediaUploader))
    }
    @State private var name: String = ""
    @State private var zoneId: Int? = nil
    @State private var islandId: Int? = nil
    @State private var shoreId: Int? = nil
    @State private var state: String = ""
    @State private var city: String = ""
    @State private var zipCode: String = ""
    @State private var address: String = ""
    @State private var latitude: String = ""
    @State private var longitude: String = ""
    @State private var ZoneName: String = ""
    @State private var ShoreName: String = ""
    @State private var IslandName: String = ""
    @State private var moveToNext: Bool = false
    @State private var showTimingPopup: Bool = false
    @State private var showLocationPopup: Bool = false
    @State private var showZonePopup: Bool = false
    @State private var showIslandPopup: Bool = false
    @State private var showShorePopup: Bool = false
    @State private var editedBusinessHours: [BusinessHours] = []
    @State private var editedLocation: String = ""
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var newImagePaths: [String] = []
    @State private var uploadedImages: [UIImage] = []
    @State private var previousImageCount: Int = 0
    @State private var showLimitAlert: Bool = false
    @State private var mapCoordinate: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 0, longitude: 0)

    private let imageBasePath = AppConfiguration.API.imageBaseURL

    private func normalizePath(_ path: String) -> String {
        return path.replacingOccurrences(of: "\\", with: "/")
    }

    private var headerView: some View {
        HStack {
            Button(action: {
                moveToNext = true
            }) {
                Image("Group1")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50)
            }
            Spacer()
        }
    }

    private var businessInfoView: some View {
        VStack(spacing: 20) {
            logoImageView()
            
            Text(viewModel.dashboard?.name ?? "Business Dashboard")
                .font(.title2)
                .fontWeight(.medium)
                .multilineTextAlignment(.center)
                .foregroundColor(.blue)
            
            if let businessType = viewModel.dashboard?.businessType, !businessType.isEmpty {
                Text(businessType)
                    .font(.title3)
                    .fontWeight(.regular)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.black)
                    .padding(.top, -10)
            }
            
            if let yearOfEstablishment = viewModel.dashboard?.yearOfEstablishment, yearOfEstablishment > 0 {
                Text("Date of Establishment: \(String(yearOfEstablishment))")
                    .font(.body)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.gray, lineWidth: 1)
                    )
            }
            
            if let description = viewModel.dashboard?.description, !description.isEmpty {
                Text(description)
                    .font(.callout)
                    .fontWeight(.regular)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.gray)
                    .padding(.top, 0)
            }
        }
    }

//    private var gallerySectionView: some View {
//        VStack(spacing: 20) {
//            HStack {
//                Text("Gallery")
//                    .font(.title2)
//                    .fontWeight(.bold)
//                Spacer()
//            }
//            .padding(.top, 0)
//            
//            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
//                ForEach(viewModel.dashboard?.imagesPath ?? [], id: \.self) { imagePath in
//                    galleryImageView(imagePath: imagePath, isNew: false)
//                }
//                ForEach(newImagePaths, id: \.self) { imagePath in
//                    galleryImageView(imagePath: imagePath, isNew: true)
//                }
//                if (viewModel.dashboard?.imagesPath.count ?? 0) + newImagePaths.count < 6 {
//                    PhotosPicker(
//                        selection: $selectedPhotos,
//                        maxSelectionCount: 6 - ((viewModel.dashboard?.imagesPath.count ?? 0) + newImagePaths.count),
//                        matching: .images
//                    ) {
//                        VStack {
//                            Image(systemName: "plus.circle.fill")
//                                .resizable()
//                                .scaledToFit()
//                                .frame(width: 30, height: 30)
//                                .foregroundColor(.blue)
//                        }
//                        .frame(height: 100)
//                        .frame(maxWidth: .infinity)
//                        .overlay(
//                            RoundedRectangle(cornerRadius: 8)
//                                .stroke(Color.gray, lineWidth: 1)
//                        )
//                    }
//                    .onChange(of: selectedPhotos) { _, newPhotos in
//                        Task {
//                            var uiImages: [UIImage] = []
//                            newImagePaths.removeAll()
//                            for photo in newPhotos {
//                                if let data = try? await photo.loadTransferable(type: Data.self),
//                                   let uiImage = UIImage(data: data) {
//                                    uiImages.append(uiImage)
//                                    let imagePath = "uploaded_image_\(UUID().uuidString).jpg"
//                                    newImagePaths.append(imagePath)
//                                }
//                            }
//                        }
//                    }
//                }
//            }
//            .padding(.top, 0)
//            
//            if !newImagePaths.isEmpty {
//                Button(action: {
//                    if stepFourViewModel.isSuccess {
//                        Task {
//                            await viewModel.GetBusinessDashboard()
//                            // Verify new images are in dashboard before clearing
//                            if viewModel.dashboard?.imagesPath.contains(where: { newImagePaths.contains($0) }) ?? false {
//                                newImagePaths.removeAll()
//                            } else {
//                            }
//                        }
//                    }
//                }) {
//                    Text("Update")
//                        .font(.headline)
//                        .foregroundColor(.white)
//                        .padding()
//                        .frame(maxWidth: .infinity)
//                        .background(stepFourViewModel.isSuccess ? Color.blue : Color.gray)
//                        .cornerRadius(10)
//                }
//                .padding(.top, 10)
//                .disabled(stepFourViewModel.isLoading || !stepFourViewModel.isSuccess)
//            }
//        }
//    }
    private var gallerySectionView: some View {
        VStack(spacing: 20) {
            HStack {
                Text("Add Business Images")
                    .font(.body)
                    .foregroundColor(.black)
                    .fontWeight(.medium)
                Spacer()
            }
            .padding(.top, 0)
            
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 10),
                GridItem(.flexible(), spacing: 10),
                GridItem(.flexible(), spacing: 10)
            ], spacing: 10) {
                ForEach(viewModel.dashboard?.imagesPath ?? [], id: \.self) { imagePath in
                    galleryImageView(imagePath: imagePath, isNew: false)
                        .frame(maxWidth: .infinity)
                }
                ForEach(Array(uploadedImages.enumerated()), id: \.offset) { index, uiImage in
                    galleryImageFromUIImage(uiImage: uiImage, index: index)
                        .frame(maxWidth: .infinity)
                }
                let existingCount = viewModel.dashboard?.imagesPath.count ?? 0
                let currentUploadedCount = uploadedImages.count
                let currentImageCount = existingCount + currentUploadedCount
                let availableSlots = 6 - currentImageCount
                
                if availableSlots > 0 {
                    PhotosPicker(
                        selection: $selectedPhotos,
                        maxSelectionCount: availableSlots, // Limit selection to available slots
                        matching: .images
                    ) {
                        VStack {
                            Image(systemName: "plus.circle.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 30, height: 30)
                                .foregroundColor(.blue)
                        }
                        .frame(height: 100)
                        .frame(maxWidth: .infinity)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray, lineWidth: 1)
                        )
                    }
                    .onChange(of: selectedPhotos) { _, newPhotos in
                        guard !newPhotos.isEmpty else { return }
                        
                        Task {
                            // Double check limit (in case user somehow selects more)
                            let existingCount = viewModel.dashboard?.imagesPath.count ?? 0
                            let currentUploadedCount = uploadedImages.count
                            let currentImageCount = existingCount + currentUploadedCount
                            let maxAllowed = 6 - currentImageCount
                            
                            if newPhotos.count > maxAllowed {
                                // Limit exceeded
                                showLimitAlert = true
                                await MainActor.run {
                                    selectedPhotos = []
                                }
                                return
                            }
                            
                            // Load images from picker
                            var uiImages: [UIImage] = []
                            for photo in newPhotos {
                                if let data = try? await photo.loadTransferable(type: Data.self),
                                   let uiImage = UIImage(data: data) {
                                    uiImages.append(uiImage)
                                }
                            }
                            
                            
                            guard !uiImages.isEmpty else {
                                await MainActor.run {
                                    selectedPhotos = []
                                }
                                return
                            }
                            
                            // Show images immediately in UI
                            await MainActor.run {
                                uploadedImages.append(contentsOf: uiImages)
                            }
                            
                            let userId = AppSessionSnapshot.userID
                            guard !userId.isEmpty else {
                                return
                            }
                            // Upload to server (this is not async, uses completion handler)
                            stepFourViewModel.uploadBusinesslogo(
                                UserID: userId,
                                image: UIImage(),
                                images: uiImages
                            )
                            
                            // Clear selection after starting upload
                            await MainActor.run {
                                selectedPhotos = []
                            }
                        }
                    }
                }
            }
            .padding(.top, 0)
        }
    }
    private var locationSectionView: some View {
        VStack(spacing: 10) {
            HStack {
                Text("Location")
                    .font(.body)
                    .foregroundColor(.black)
                    .fontWeight(.medium)
                Spacer()
                Button(action: {
                    showLocationPopup = true
                    editedLocation = viewModel.dashboard?.location ?? "123 Main Street"
                }) {
                    Text("Edit")
                        .font(.body)
                        .foregroundColor(.blue)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.blue, lineWidth: 1)
                        )
                }
            }
            .padding(.top, 10)
            
            SectionCard(borderColor: Color.gray.opacity(0.6), showShadow: false) {
                Text("Address: \(editedLocation.isEmpty ? (viewModel.dashboard?.location ?? "123 Main Street") : editedLocation)")
                    .foregroundColor(.gray)
            }
            .padding(.top, 0)
        }
    }

    private var businessTimingsView: some View {
        VStack(spacing: 10) {
            HStack {
                Text("Add Business Hours")
                    .font(.body)
                    .fontWeight(.medium)
                Spacer()
                Button(action: {
                    editedBusinessHours = viewModel.dashboard?.businessHours ?? []
                    showTimingPopup = true
                }) {
                    Text("Edit")
                        .font(.body)
                        .foregroundColor(.blue)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.blue, lineWidth: 1)
                        )
                }
            }
            .padding(.top, 10)
            
            SectionCard(borderColor: Color.gray.opacity(0.6), showShadow: false) {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(viewModel.dashboard?.businessHours ?? [], id: \.day) { hour in
                        HStack {
                            Text(hour.day)
                                .fontWeight(.medium)
                                .foregroundColor(.gray)
                            Spacer()
                            Text("\(hour.startTime) - \(hour.endTime)")
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
            .padding(.top, 0)
        }
    }

    private var dockToggleView: some View {
        HStack {
            Text("Add Dock")
                .font(.headline)
            Toggle("", isOn: $isDockAdded)
                .labelsHidden()
                .tint(.blue)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.leading, -15)
    }

    private var buttonsView: some View {
        HStack {
//            Button(action: {
//                newImagePaths.removeAll() // Clear unsaved images
//                viewModel.GetBusinessDashboard()
//            }) {
//                Text("Cancel")
//                    .padding()
//                    .frame(maxWidth: .infinity)
//                    .background(Color.blue)
//                    .foregroundColor(.white)
//                    .cornerRadius(10)
//                    .overlay(
//                        RoundedRectangle(cornerRadius: 10)
//                            .stroke(Color.blue, lineWidth: 1)
//                    )
//            }
            
            PrimaryButton(
                title: "Save And Proceed",
                isLoading: viewModel.isUploadLoading,
                isDisabled: false
            ) {
                viewModel.uploadBusinessDashboard(
                    location: editedLocation,
                    businessHours: editedBusinessHours,
                    isDock: isDockAdded,
                    name: name,
                    shoreId: shoreId ?? 0,
                    zoneId: zoneId ?? 0,
                    islandId: islandId ?? 0,
                    zipCode: zipCode,
                    shoreLine: ShoreName,
                    address: address,
                    latitude: latitude,
                    longitude: longitude
                )
            }
        }
        .padding(.top, 30)
    }

    private func logoImageView() -> some View {
        let path = normalizePath(viewModel.dashboard?.logoPath ?? "")
        let logoUrlString = imageBasePath + path
        return WebImage(url: URL(string: logoUrlString)) { image in
            image
                .resizable()
                .scaledToFit()
                .frame(width: 90, height: 90)
                .cornerRadius(20)
                .clipped()
        } placeholder: {
            Image(systemName: "photo")
                .resizable()
                .scaledToFit()
                .frame(width: 90, height: 90)
                .foregroundColor(.gray)
                .cornerRadius(20)
                .clipped()
        }
        .onFailure { error in
        }
        .frame(width: 90, height: 90)
    }

//    private func galleryImageView(imagePath: String, isNew: Bool) -> some View {
//        let normalizedPath = normalizePath(imagePath)
//        let imageUrlString = imageBasePath + normalizedPath
//        return ZStack(alignment: .topLeading) {
//            WebImage(url: URL(string: imageUrlString)) { image in
//                image
//                    .resizable()
//                    .scaledToFill()
//                    .frame(height: 100)
//                    .cornerRadius(8)
//                    .clipped()
//                    .overlay(
//                        RoundedRectangle(cornerRadius: 8)
//                            .stroke(Color.gray, lineWidth: 1)
//                    )
//            } placeholder: {
//                Image(systemName: "photo.fill")
//                    .resizable()
//                    .scaledToFill()
//                    .frame(height: 100)
//                    .foregroundColor(.gray)
//                    .clipped()
//                    .overlay(
//                        RoundedRectangle(cornerRadius: 8)
//                            .stroke(Color.gray, lineWidth: 1)
//                    )
//            }
//            .onFailure { error in
//            }
//            .frame(height: 100)
//            
//            Button(action: {
//                if isNew {
//                    newImagePaths.removeAll { $0 == imagePath }
//                } else {
//                    viewModel.DeleteImage(Path: imagePath) { _ in
//                        viewModel.GetBusinessDashboard()
//                    }
//                }
//            }) {
//                Image(systemName: "xmark.circle.fill")
//                    .foregroundColor(.red)
//                    .frame(width: 24, height: 24)
//                    .background(Circle().fill(Color.white))
//                    .offset(x: -8, y: 8)
//            }
//            .disabled(viewModel.isDeleteimageLoading)
//        }
//        .overlay {
//            if viewModel.isDeleteimageLoading {
//                ProgressView()
//                    .progressViewStyle(CircularProgressViewStyle())
//                    .tint(.white)
//                    .scaleEffect(1.2)
//                    .background(Color.black.opacity(0.3))
//                    .cornerRadius(8)
//            }
//        }
//    }
    
    private func galleryImageView(imagePath: String, isNew: Bool) -> some View {
        let normalizedPath = normalizePath(imagePath)
        let encodedPath = normalizedPath.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? normalizedPath
        let imageUrlString = imageBasePath + encodedPath
        return ZStack(alignment: .topLeading) {
            WebImage(url: URL(string: imageUrlString))
                .resizable()
                .scaledToFit() // Changed from scaledToFill to prevent overflow
                .frame(height: 100)
                .cornerRadius(8)
                .clipped()
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray, lineWidth: 1)
                )
            
            Button(action: {
                viewModel.DeleteImage(Path: imagePath) { _ in
                    viewModel.GetBusinessDashboard()
                }
            }) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.red)
                    .frame(width: 24, height: 24)
                    .background(Circle().fill(Color.white))
                    .offset(x: -8, y: 8)
            }
            .disabled(viewModel.isDeleteimageLoading)
        }
        .frame(height: 100)
        .overlay {
            if viewModel.isDeleteimageLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .tint(.white)
                    .scaleEffect(1.2)
                    .background(Color.black.opacity(0.3))
                    .cornerRadius(8)
            }
        }
    }
    
    private func galleryImageFromUIImage(uiImage: UIImage, index: Int) -> some View {
        return ZStack(alignment: .topLeading) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .frame(height: 100)
                .cornerRadius(8)
                .clipped()
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray, lineWidth: 1)
                )
            
            Button(action: {
                uploadedImages.remove(at: index)
            }) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.red)
                    .frame(width: 24, height: 24)
                    .background(Circle().fill(Color.white))
                    .offset(x: -8, y: 8)
            }
        }
        .frame(height: 100)
    }
    private func saveImageToServer(data: Data) -> String? {
        return "uploaded_image_\(UUID().uuidString).jpg"
    }

    var body: some View {
        NavigationView {
            ZStack {
                ScrollView {
                    VStack(spacing: 20) {
                        headerView
                        businessInfoView
                        gallerySectionView
                        locationSectionView
                        businessTimingsView
                        dockToggleView
                        
                        if isDockAdded {
                            DockFormView(
                                name: $name,
                                zoneId: $zoneId,
                                islandId: $islandId,
                                shoreId: $shoreId,
                                ZoneName: $ZoneName,
                                IslandName: $IslandName,
                                ShoreName: $ShoreName,
                                state: $state,
                                city: $city,
                                zipCode: $zipCode,
                                address: $address,
                                latitude: $latitude,
                                longitude: $longitude,
                                showZonePopup: $showZonePopup,
                                showIslandPopup: $showIslandPopup,
                                showShorePopup: $showShorePopup,
                                viewModel: viewModel
                            )
                        }
                        
                        buttonsView
                        
                        NavigationLink(destination: SpinWheelMenu(username: "Business"), isActive: $moveToNext) {
                            EmptyView()
                                .navigationBarBackButtonHidden(true)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 80)
                }
                .background(Color.white)
                .navigationBarHidden(true)
                .ignoresSafeArea(edges: .top)
                .onAppear {
                    viewModel.GetBusinessDashboard()
                    viewModel.Getlockeddocked()
                }
                .onChange(of: stepFourViewModel.isSuccess) { _, isSuccess in
                    if isSuccess {
                        previousImageCount = viewModel.dashboard?.imagesPath.count ?? 0
                        viewModel.refreshDashboardAfterUpload()
                    } else {
                        // If upload failed, check if we should remove uploaded images
                        // Only remove if there's an error message indicating failure
                        if !stepFourViewModel.message.isEmpty && !stepFourViewModel.isLoading {
                            // Optionally remove failed images from UI after a delay
                            // This allows user to see which images failed
                        }
                    }
                }
                .onChange(of: stepFourViewModel.message) { _, message in
                    // Log upload status messages
                    if !message.isEmpty {
                    }
                }
                .onChange(of: viewModel.dashboard) { _, newDashboard in
                    if let dashboard = newDashboard {
                        // Clear uploaded images if dashboard has been refreshed after upload
                        // Check if we have uploaded images and dashboard count increased
                        if !uploadedImages.isEmpty {
                            let newCount = dashboard.imagesPath.count
                            // If dashboard has more images than before, clear uploaded images
                            if newCount > previousImageCount {
                                uploadedImages.removeAll()
                            }
                        }
                        isDockAdded = dashboard.isDock
                        if dashboard.isDock {
                            name = dashboard.name
                            zoneId = dashboard.zoneId
                            islandId = dashboard.islandId
                            shoreId = dashboard.shoreId
                            ZoneName = dashboard.ZoneName
                            IslandName = dashboard.IslandName
                            ShoreName = dashboard.ShoreName
                            state = dashboard.state
                            city = dashboard.city
                            zipCode = dashboard.zipCode
                            address = dashboard.address
                            latitude = String(dashboard.latitude)
                            longitude = String(dashboard.longitude)
                        } else {
                            name = ""
                            zoneId = nil
                            islandId = nil
                            shoreId = nil
                            ZoneName = ""
                            IslandName = ""
                            ShoreName = ""
                            state = ""
                            city = ""
                            zipCode = ""
                            address = ""
                            latitude = ""
                            longitude = ""
                        }
                    }
                }
                .sheet(isPresented: $showTimingPopup) {
                    VStack(spacing: 20) {
                        Text("Edit Business Timings")
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding(.top, 20)
                        
                        ScrollView {
                            VStack(alignment: .leading, spacing: 15) {
                                ForEach(viewModel.dashboard?.businessHours ?? [], id: \.day) { hour in
                                    // Find index in editedBusinessHours or create new binding
                                    if let index = editedBusinessHours.firstIndex(where: { $0.day == hour.day }) {
                                        BusinessHoursRow(hour: Binding(
                                            get: { editedBusinessHours[index] },
                                            set: { editedBusinessHours[index] = $0 }
                                        ))
                                    } else {
                                        // If not found, use original hour
                                        BusinessHoursRow(hour: Binding(
                                            get: { hour },
                                            set: { newValue in
                                                editedBusinessHours.append(newValue)
                                            }
                                        ))
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                        .onAppear {
                            // Load data from dashboard when sheet appears
                            if let dashboardHours = viewModel.dashboard?.businessHours {
                                editedBusinessHours = dashboardHours
                            }
                        }
                        
                        Button(action: {
                            // Update local state first
                            if var dashboard = viewModel.dashboard {
                                dashboard.businessHours = editedBusinessHours
                                viewModel.dashboard = dashboard
                            }
                            
                            // Call API to save business hours along with other dashboard data
                            viewModel.uploadBusinessDashboard(
                                location: editedLocation.isEmpty ? (viewModel.dashboard?.location ?? "") : editedLocation,
                                businessHours: editedBusinessHours,
                                isDock: isDockAdded,
                                name: name.isEmpty ? (viewModel.dashboard?.name ?? "") : name,
                                shoreId: shoreId ?? (viewModel.dashboard?.shoreId ?? 0),
                                zoneId: zoneId ?? (viewModel.dashboard?.zoneId ?? 0),
                                islandId: islandId ?? (viewModel.dashboard?.islandId ?? 0),
                                zipCode: zipCode.isEmpty ? (viewModel.dashboard?.zipCode ?? "") : zipCode,
                                shoreLine: ShoreName.isEmpty ? (viewModel.dashboard?.ShoreName ?? "") : ShoreName,
                                address: address.isEmpty ? (viewModel.dashboard?.address ?? "") : address,
                                latitude: latitude.isEmpty ? String(viewModel.dashboard?.latitude ?? 0.0) : latitude,
                                longitude: longitude.isEmpty ? String(viewModel.dashboard?.longitude ?? 0.0) : longitude
                            )
                            
                            showTimingPopup = false
                        }) {
                            Text("OK")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.blue)
                                .cornerRadius(10)
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 20)
                    }
                    .presentationDetents([.medium, .large])
                }
                .sheet(isPresented: $showLocationPopup) {
                    LocationPickerView(
                        coordinate: $mapCoordinate,
                        address: $editedLocation,
                        latitude: $latitude,
                        longitude: $longitude
                    )
                    .presentationDetents([.medium, .large])
                }
                .alert(isPresented: Binding<Bool>(
                    get: { viewModel.errorMessage != nil },
                    set: { _ in viewModel.errorMessage = nil }
                )) {
                    Alert(
                        title: Text("Error"),
                        message: Text(viewModel.errorMessage ?? "An error occurred"),
                        dismissButton: .default(Text("OK"))
                    )
                }
                .alert(isPresented: Binding<Bool>(
                    get: { stepFourViewModel.message != "" },
                    set: { _ in stepFourViewModel.message = "" }
                )) {
                    Alert(
                        title: Text(stepFourViewModel.isSuccess ? "Success" : "Error"),
                        message: Text(stepFourViewModel.message),
                        dismissButton: .default(Text("OK"))
                    )
                }
                .alert(isPresented: $showLimitAlert) {
                    Alert(
                        title: Text("Limit Reached"),
                        message: Text("You can upload maximum 6 images. Limit complete."),
                        dismissButton: .default(Text("OK"))
                    )
                }
                
                if viewModel.isDashboardLoading || viewModel.isUploadLoading || stepFourViewModel.isLoading {
                    ZStack {
                        Color.black.opacity(0.3)
                            .ignoresSafeArea()
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .scaleEffect(1.5)
                            .tint(.white)
                    }
                }
            }
        }
        .navigationBarBackButtonHidden(true)
    }
}

struct LocationPickerView: View {
    @Binding var coordinate: CLLocationCoordinate2D
    @Binding var address: String
    @Binding var latitude: String
    @Binding var longitude: String
    @Environment(\.dismiss) var dismiss
    @State private var region: MKCoordinateRegion
    @StateObject private var locationManager = LocationManager()

    init(coordinate: Binding<CLLocationCoordinate2D>, address: Binding<String>, latitude: Binding<String>, longitude: Binding<String>) {
        self._coordinate = coordinate
        self._address = address
        self._latitude = latitude
        self._longitude = longitude
        let initialCoordinate = coordinate.wrappedValue
        self._region = State(initialValue: MKCoordinateRegion(
            center: initialCoordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        ))
    }
    
    var body: some View {
        VStack {
            Text("Select Location")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.top, 20)
            
            Map(position: .constant(.region(region))) {
                Annotation("Pin", coordinate: region.center) {
                    Image(systemName: "mappin.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 30, height: 30)
                        .foregroundColor(.red)
                }
            }
            .frame(maxHeight: .infinity)
            
            Text(address.isEmpty ? "Fetching address..." : address)
                .font(.subheadline)
                .foregroundColor(.gray)
                .padding(.horizontal)
                .multilineTextAlignment(.center)
            
            Button(action: {
                coordinate = region.center
                latitude = String(region.center.latitude)
                longitude = String(region.center.longitude)
                dismiss()
            }) {
                Text("Select")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .padding(.horizontal)
            .padding(.bottom, 20)
        }
        .onChange(of: region.center) { _, newCenter in
            coordinate = newCenter
            updateAddress()
        }
        .onReceive(locationManager.$currentLocation) { newLocation in
            if let location = newLocation {
                region.center = location
                coordinate = location
                updateAddress()
            } else {
                // Fallback to San Francisco if current location is unavailable
                let defaultCoordinate = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
                region = MKCoordinateRegion(
                    center: defaultCoordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                )
                coordinate = defaultCoordinate
                updateAddress()
            }
        }
        .onAppear {
            // Check if we already have a location from LocationManager
            if let location = locationManager.currentLocation {
                region.center = location
                coordinate = location
                updateAddress()
            } else {
                // Fallback to San Francisco until LocationManager provides a location
                let defaultCoordinate = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
                region = MKCoordinateRegion(
                    center: defaultCoordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                )
                coordinate = defaultCoordinate
                updateAddress()
            }
        }
    }
    
    private func updateAddress() {
        let geocoder = CLGeocoder()
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            if let error = error {
                address = "Unable to fetch address"
                return
            }
            if let placemark = placemarks?.first {
                let components = [
                    placemark.subThoroughfare,
                    placemark.thoroughfare,
                    placemark.locality,
                    placemark.administrativeArea,
                    placemark.postalCode,
                    placemark.country
                ].compactMap { $0 }
                address = components.joined(separator: ", ")
            } else {
                address = "Unknown location"
            }
        }
    }
}

struct Location: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
}

struct BusinessHoursRow: View {
    @Binding var hour: BusinessHours

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(hour.day)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.black)
            
            HStack(spacing: 10) {
                TextField("Start Time", text: $hour.startTime)
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 8).stroke(Color.black, lineWidth: 1))
                    .cornerRadius(8)
                
                TextField("End Time", text: $hour.endTime)
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 8).stroke(Color.black, lineWidth: 1))
                    .cornerRadius(8)
            }
        }
    }
}

struct DockFormView: View {
    @Binding var name: String
    @Binding var zoneId: Int?
    @Binding var islandId: Int?
    @Binding var shoreId: Int?
    @Binding var ZoneName: String
    @Binding var IslandName: String
    @Binding var ShoreName: String
    @Binding var state: String
    @Binding var city: String
    @Binding var zipCode: String
    @Binding var address: String
    @Binding var latitude: String
    @Binding var longitude: String
    @Binding var showZonePopup: Bool
    @Binding var showIslandPopup: Bool
    @Binding var showShorePopup: Bool
    @ObservedObject var viewModel: DashboardVCViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack(spacing: 15) {
                VStack(alignment: .leading) {
                    HStack {
                        Image(systemName: "person.text.rectangle")
                            .foregroundColor(.blue)
                            .frame(width: 20, height: 20)
                        Text("Name")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                    .padding(.bottom, 5)
                    TextField("Enter name", text: $name)
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 8).stroke(Color.black, lineWidth: 1))
                        .cornerRadius(8)
                }
                
                VStack(alignment: .leading) {
                    HStack {
                        Image(systemName: "mappin")
                            .foregroundColor(.blue)
                            .frame(width: 20, height: 20)
                        Text("Zone")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                    .padding(.bottom, 5)
                    Text(ZoneName.isEmpty ? "Select Zone" : ZoneName)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(RoundedRectangle(cornerRadius: 8).stroke(Color.black, lineWidth: 1))
                        .cornerRadius(8)
                        .foregroundColor(.black)
                        .onTapGesture {
                            showZonePopup = true
                        }
                        .sheet(isPresented: $showZonePopup) {
                            VStack {
                                Text("Select Zone")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .padding(.top, 20)
                                
                                if viewModel.isDashboardLoading {
                                    ProgressView()
                                        .padding()
                                } else if viewModel.zoneItems.isEmpty {
                                    Text("No zones available")
                                        .foregroundColor(.gray)
                                        .padding()
                                } else {
                                    List(viewModel.zoneItems) { zone in
                                        Button(action: {
                                            zoneId = zone.id
                                            ZoneName = zone.name
                                            showZonePopup = false
                                        }) {
                                            Text(zone.name)
                                                .foregroundColor(.black)
                                        }
                                    }
                                }
                                
                                Button(action: {
                                    showZonePopup = false
                                }) {
                                    Text("Cancel")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .padding()
                                        .frame(maxWidth: .infinity)
                                        .background(Color.blue)
                                        .cornerRadius(10)
                                }
                                .padding(.horizontal)
                                .padding(.bottom, 20)
                            }
                            .presentationDetents([.medium])
                        }
                }
            }
            
            HStack(spacing: 15) {
                VStack(alignment: .leading) {
                    HStack {
                        Image(systemName: "map")
                            .foregroundColor(.blue)
                            .frame(width: 20, height: 20)
                        Text("State")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                    .padding(.bottom, 5)
                    TextField("Enter state", text: $state)
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 8).stroke(Color.black, lineWidth: 1))
                        .cornerRadius(8)
                }
                
                VStack(alignment: .leading) {
                    HStack {
                        Image(systemName: "building.2")
                            .foregroundColor(.blue)
                            .frame(width: 20, height: 20)
                        Text("City")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                    .padding(.bottom, 5)
                    TextField("Enter city", text: $city)
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 8).stroke(Color.black, lineWidth: 1))
                        .cornerRadius(8)
                }
            }
            
            HStack(spacing: 15) {
                VStack(alignment: .leading) {
                    HStack {
                        Image(systemName: "envelope")
                            .foregroundColor(.blue)
                            .frame(width: 20, height: 20)
                        Text("Zip Code")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                    .padding(.bottom, 5)
                    TextField("Enter zip code", text: $zipCode)
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 8).stroke(Color.black, lineWidth: 1))
                        .cornerRadius(8)
                }
                
                VStack(alignment: .leading) {
                    HStack {
                        Image(systemName: "anchor")
                            .foregroundColor(.blue)
                            .frame(width: 20, height: 20)
                        Text("Shore")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                    .padding(.bottom, 5)
                    Text(ShoreName.isEmpty ? "Select Shore" : ShoreName)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(RoundedRectangle(cornerRadius: 8).stroke(Color.black, lineWidth: 1))
                        .cornerRadius(8)
                        .foregroundColor(.black)
                        .onTapGesture {
                            showShorePopup = true
                        }
                        .sheet(isPresented: $showShorePopup) {
                            VStack {
                                Text("Select Shore")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .padding(.top, 20)
                                
                                if viewModel.isDashboardLoading {
                                    ProgressView()
                                        .padding()
                                } else if viewModel.shoreItems.isEmpty {
                                    Text("No shores available")
                                        .foregroundColor(.gray)
                                        .padding()
                                } else {
                                    List(viewModel.shoreItems) { shore in
                                        Button(action: {
                                            shoreId = shore.id
                                            ShoreName = shore.name
                                            showShorePopup = false
                                        }) {
                                            Text(shore.name)
                                                .foregroundColor(.black)
                                        }
                                    }
                                }
                                
                                Button(action: {
                                    showShorePopup = false
                                }) {
                                    Text("Cancel")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .padding()
                                        .frame(maxWidth: .infinity)
                                        .background(Color.blue)
                                        .cornerRadius(10)
                                }
                                .padding(.horizontal)
                                .padding(.bottom, 20)
                            }
                            .presentationDetents([.medium])
                        }
                }
            }
            
            HStack(spacing: 15) {
                VStack(alignment: .leading) {
                    HStack {
                        Image(systemName: "location")
                            .foregroundColor(.blue)
                            .frame(width: 20, height: 20)
                        Text("Address")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                    .padding(.bottom, 5)
                    TextField("Enter address", text: $address)
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 8).stroke(Color.black, lineWidth: 1))
                        .cornerRadius(8)
                }
                
                VStack(alignment: .leading) {
                    HStack {
                        Image(systemName: "globe.europe.africa")
                            .foregroundColor(.blue)
                            .frame(width: 20, height: 20)
                        Text("Island")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                    .padding(.bottom, 5)
                    Text(IslandName.isEmpty ? "Select Island" : IslandName)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(RoundedRectangle(cornerRadius: 8).stroke(Color.black, lineWidth: 1))
                        .cornerRadius(8)
                        .foregroundColor(.black)
                        .onTapGesture {
                            showIslandPopup = true
                        }
                        .sheet(isPresented: $showIslandPopup) {
                            VStack {
                                Text("Select Island")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .padding(.top, 20)
                                
                                if viewModel.isDashboardLoading {
                                    ProgressView()
                                        .padding()
                                } else if viewModel.islandItems.isEmpty {
                                    Text("No islands available")
                                        .foregroundColor(.gray)
                                        .padding()
                                } else {
                                    List(viewModel.islandItems) { island in
                                        Button(action: {
                                            islandId = island.id
                                            IslandName = island.name
                                            showIslandPopup = false
                                        }) {
                                            Text(island.name)
                                                .foregroundColor(.black)
                                        }
                                    }
                                }
                                
                                Button(action: {
                                    showIslandPopup = false
                                }) {
                                    Text("Cancel")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .padding()
                                        .frame(maxWidth: .infinity)
                                        .background(Color.blue)
                                        .cornerRadius(10)
                                }
                                .padding(.horizontal)
                                .padding(.bottom, 20)
                            }
                            .presentationDetents([.medium])
                        }
                }
            }
            
            HStack(spacing: 15) {
                VStack(alignment: .leading) {
                    HStack {
                        Image(systemName: "globe.europe.africa")
                            .foregroundColor(.blue)
                            .frame(width: 20, height: 20)
                        Text("Longitude")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                    .padding(.bottom, 5)
                    TextField("Enter longitude", text: $longitude)
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 8).stroke(Color.black, lineWidth: 1))
                        .cornerRadius(8)
                }
                
                VStack(alignment: .leading) {
                    HStack {
                        Image(systemName: "globe.americas")
                            .foregroundColor(.blue)
                            .frame(width: 20, height: 20)
                        Text("Latitude")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                    .padding(.bottom, 5)
                    TextField("Enter latitude", text: $latitude)
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 8).stroke(Color.black, lineWidth: 1))
                        .cornerRadius(8)
                }
            }
        }
        .padding(.bottom, 20)
    }
}

extension CLLocationCoordinate2D: Equatable {
    public static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        return lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
    }
}


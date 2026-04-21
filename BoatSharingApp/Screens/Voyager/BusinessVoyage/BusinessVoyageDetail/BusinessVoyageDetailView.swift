import SwiftUI

struct BusinessVoyageDetailView: View {
    @EnvironmentObject private var uiFlowState: UIFlowState
    let business: BusinessRelationship
    let imageBasePath: String
    @Environment(\.presentationMode) var presentationMode
    @State private var showVoyagePopup = false
    @State private var navigateToVoyagerHome = false

    let gridColumns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .center, spacing: 16) {
                    // Centered Logo Image
                    if business.logoPath.isEmpty || URL(string: imageBasePath + business.logoPath.replacingOccurrences(of: "\\", with: "/")) == nil {
                        Image("b_logo")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 100, height: 100)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .padding(.top)
                    } else {
                        AsyncImage(url: URL(string: imageBasePath + business.logoPath.replacingOccurrences(of: "\\", with: "/"))) { image in
                            image.resizable()
                                .scaledToFill()
                        } placeholder: {
                            Image("b_logo")
                                .resizable()
                                .scaledToFill()
                                .frame(width: 100, height: 100)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        .frame(width: 100, height: 100)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.top)
                    }

                    // Centered Business Name, Type, and Year
                    VStack(spacing: 4) {
                        Text(business.name)
                            .font(.title2)
                            .bold()
                            .multilineTextAlignment(.center)

                        Text(business.businessType.capitalized)
                            .font(.subheadline)
                            .foregroundColor(.gray)

                        Text("Established: \(business.yearOfEstablishment)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        // Buttons Section
                        HStack(spacing: 16) {
                            Button(action: {
                                // Follow action (implement as needed)
                            }) {
                                Text("Followed")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                    .padding(.vertical, 10)
                                    .padding(.horizontal, 20)
                                    .background(Color.AppColor)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }

                            Button(action: {
                                showVoyagePopup = true
                            }) {
                                Text("Add Voyage")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.AppColor)
                                    .padding(.vertical, 10)
                                    .padding(.horizontal, 20)
                                    .background(Color.white)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.AppColor, lineWidth: 1)
                                    )
                            }
                        }
                        .padding(.top, 8)
                    }
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)

                    // Description Section
                    if !business.description.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Description")
                                .font(.headline)
                            Text(business.description)
                                .font(.body)
                                .foregroundColor(.primary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top)
                    }

                    // Gallery Section
                    if !business.imagesPath.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Gallery")
                                .font(.headline)

                            LazyVGrid(columns: gridColumns, spacing: 10) {
                                ForEach(business.imagesPath, id: \.self) { path in
                                    AsyncImage(url: URL(string: imageBasePath + path.replacingOccurrences(of: "\\", with: "/"))) { image in
                                        image.resizable()
                                            .scaledToFill()
                                    } placeholder: {
                                        Color.gray.opacity(0.2)
                                    }
                                    .frame(width: 100, height: 80)
                                    .clipped()
                                    .cornerRadius(8)
                                }
                            }
                        }
                        .padding(.top)
                    }

                    // Location Section
                    if !business.location.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Location")
                                .font(.headline)

                            Text(business.location)
                                .font(.body)
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding()
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.AppColor, lineWidth: 1)
                                )
                        }
                        .padding(.top)
                    }

                    // Business Hours Section
                    if !business.businessHours.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Business Hours")
                                .font(.headline)

                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(business.businessHours, id: \.day) { hour in
                                    HStack {
                                        Text(hour.day)
                                            .frame(width: 100, alignment: .leading)
                                        Spacer()
                                        Text("\(hour.startTime) - \(hour.endTimeTime)")
                                    }
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                }
                            }
                            .padding()
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.AppColor, lineWidth: 1)
                            )
                        }
                        .padding(.top)
                    }

                    Spacer()
                }
                .padding()
            }
            .onAppear {
            }
            .navigationBarBackButtonHidden(true)
            .navigationBarItems(leading:
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    HStack {
                        Image(systemName: "arrow.backward")
                            .foregroundColor(Color.black)
                    }
                }
            )
            .navigationTitle("Business Detail")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showVoyagePopup) {
                VStack(spacing: 20) {
                    Text("Select its Business as:")
                        .font(.headline)
                        .padding(.top, 20)

                    HStack(spacing: 16) {
                        Button(action: {
                            uiFlowState.businessVoyageSelection = BusinessVoyageSelection(
                                businessID: String(business.id),
                                businessName: business.name,
                                voyageType: .pickup
                            )
                            showVoyagePopup = false
                            navigateToVoyagerHome = true
                        }) {
                            Text("Pick-up")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.AppColor)
                                .padding(.vertical, 10)
                                .padding(.horizontal, 20)
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .shadow(radius: 2)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.AppColor, lineWidth: 1)
                                )
                        }

                        Button(action: {
                            uiFlowState.businessVoyageSelection = BusinessVoyageSelection(
                                businessID: String(business.id),
                                businessName: business.name,
                                voyageType: .dropoff
                            )
                            
                            showVoyagePopup = false
                            navigateToVoyagerHome = true
                        }) {
                            Text("Drop-off")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.AppColor)
                                .padding(.vertical, 10)
                                .padding(.horizontal, 20)
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .shadow(radius: 2)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.AppColor, lineWidth: 1)
                                )
                        }
                    }
                    Spacer()
                }
                .padding()
                .presentationDetents([.medium])
            }
            .navigationDestination(isPresented: $navigateToVoyagerHome) {
                VoyagerHomeView()
            }
        }
    }
}

import SwiftUI

struct DockSelectionView: View {
    @Binding var showDockSelection: Bool
    @Binding var currentLocation: DockLocation?
    @Binding var dropoffLocation: DockLocation?
    @Binding var showFindBoatSheet: Bool
    let selectedField: DockFieldType?
    @State private var showDockList = false
    @State private var localSelectedField: DockFieldType? = nil
    @EnvironmentObject var viewModel: VoyagerHomeViewModel
    @EnvironmentObject var uiFlowState: UIFlowState
    
    @State private var currentDockTypeId: Int? = nil
    @State private var dropOffDockTypeId: Int? = nil

    var body: some View {
        NavigationStack {
            ZStack {
                Color.white.ignoresSafeArea()
                
                VStack(spacing: 20) {
                    VStack {
//                        Text("Find Destination")
//                            .font(.headline)
//                            .foregroundColor(Color.blue)
                        
                        DockTextField(
                            placeholder: "Current Location",
                            selectedDock: $currentLocation,
                            isSelected: localSelectedField == .current,
                            action: {
                                localSelectedField = .current
                                showDockList = true
                            }
                        )
                        
                        Rectangle()
                            .frame(height: 1)
                            .foregroundColor(Color.blue)
                            .frame(maxWidth: .infinity)
                        
                        Button(action: {
                            showDockSelection = false
                            showFindBoatSheet = true
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .resizable()
                                .frame(width: 30, height: 30)
                                .foregroundColor(Color.blue)
                                .shadow(radius: 5)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                                .padding(.top, -25)
                        }
                        
                        DockTextField(
                            placeholder: "Drop-off Location",
                            selectedDock: $dropoffLocation,
                            isSelected: localSelectedField == .dropoff,
                            action: {
                                localSelectedField = .dropoff
                                showDockList = true
                            }
                        )
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(10)
                    .shadow(radius: 5)
                    
                    if showDockList {
                        DockListView(
                            selectedDock: localSelectedField == .current ? $currentLocation : $dropoffLocation,
                            showDockList: $showDockList,
                            docks: viewModel.docks,
                            onDockSelected: { selectedDock in
                                if localSelectedField == .current {
                                    currentDockTypeId = selectedDock.dockTypeId
                                    
                                    
                                    uiFlowState.voyageDraft.pickupDockID = String(currentDockTypeId ?? 0)
                                    uiFlowState.voyageDraft.pickupLocationName = selectedDock.name
                                } else if localSelectedField == .dropoff {
                                    dropOffDockTypeId = selectedDock.dockTypeId
                                    
                                    uiFlowState.voyageDraft.dropOffDockID = String(dropOffDockTypeId ?? 0)
                                    uiFlowState.voyageDraft.dropOffLocationName = selectedDock.name
                                }
                                showDockList = false
                            }
                        )
                    }
                    
                    Spacer()
                    
                    if currentLocation != nil && dropoffLocation != nil {
                        Button(action: {
                            
                            
                            uiFlowState.voyageDraft.pickupLocationName = currentLocation?.name ?? ""
                            uiFlowState.voyageDraft.dropOffLocationName = dropoffLocation?.name ?? ""
                            showDockSelection = false
                            showFindBoatSheet = true
                        }) {
                            Text("Next")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .font(.headline)
                                .cornerRadius(10)
                                .padding(.horizontal, 20)
                                .padding(.bottom, 60)
                        }
                        .transition(.opacity)
                    }
                }
                .padding()
                .onAppear {
                    if viewModel.docks.isEmpty {
                        viewModel.send(.ensureDocksLoaded)
                    }
                    localSelectedField = selectedField
                }
            }
        }
    }
}

enum DockFieldType {
    case current, dropoff
}

struct DockTextField: View {
    var placeholder: String
    @Binding var selectedDock: DockLocation?
    var isSelected: Bool
    var action: () -> Void

    var body: some View {
        HStack {
            Image(systemName: "location.fill")
                .foregroundColor(Color.blue)

            Text(selectedDock?.name ?? placeholder)
                .foregroundColor(selectedDock == nil ? .gray : .black)

            Spacer()

            if selectedDock != nil {
                Button(action: {
                    selectedDock = nil
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(Color.blue)
                }
            }
        }
        .padding()
        .onTapGesture {
            action()
        }
    }
}

struct DockListView: View {
    @Binding var selectedDock: DockLocation?
    @Binding var showDockList: Bool
    var docks: [DockLocation]
    var onDockSelected: (DockLocation) -> Void

    var body: some View {
        List(docks) { dock in
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(dock.name)
                        .font(.headline)
                    Text(dock.address.isEmpty ? "No Address Available" : dock.address)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                Spacer()
            }
            .padding(.leading, 20)
            .contentShape(Rectangle())
            .listRowInsets(EdgeInsets())
            .listRowSeparator(.hidden)
            .onTapGesture {
                selectedDock = dock
                onDockSelected(dock)
                showDockList = false
            }
        }
        .listStyle(PlainListStyle())
        .frame(height: 200) // Reduced height to make list area smaller
        .allowsHitTesting(true) // Ensure list can receive taps
    }
}

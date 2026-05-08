import SwiftUI

struct CreateVoyageView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject private var uiFlowState: UIFlowState
    @StateObject private var viewModel: CreateVoyageViewModel
    private let dependencies: AppDependencies

    init(dependencies: AppDependencies = .live) {
        self.dependencies = dependencies
        _viewModel = StateObject(
            wrappedValue: CreateVoyageViewModel(dateFormatter: dependencies.dateFormatter)
        )
    }
    
    var body: some View {
        ZStack {
            
            VStack(spacing: 0) {

                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        
                        Image(systemName: "arrow.backward")
                            .foregroundColor(.black)
                            .padding()
                    }
                    
                    Spacer()
                    
                    Text("Create Voyage")
                        .font(.title2.bold())
                        .foregroundColor(.black)
                    
                    Spacer()
                    
                    // for alignment
                    Color.clear.frame(width: 44, height: 44)
                }
                .padding(.top, 0)
                .background(Color.white)
                
                Divider()

                VStack(alignment: .leading, spacing: 16) {
                    Toggle("Travel Now", isOn: $viewModel.isTravelNow)
                        .padding(.horizontal)
                        .padding(.top, 10)

                    if !viewModel.isTravelNow {
                        Button(action: {
                            viewModel.showCalendar.toggle()
                        }) {
                            HStack {
                                Text(viewModel.formattedDate(viewModel.selectedDate))
                                Spacer()
                                Image(systemName: "calendar")
                            }
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                        }
                        .padding(.horizontal)
                    }

                    Button(action: {
                        viewModel.showStartTimePicker.toggle()
                    }) {
                        HStack {
                            Text(viewModel.formattedTime(viewModel.selectedStartTime, placeholder: "Select Start Time"))
                            Spacer()
                            Image(systemName: "clock")
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                    }
                    .padding(.horizontal)

                    Toggle("Spend time on water", isOn: $viewModel.isSpendOnWater)
                        .padding(.horizontal)

                    if viewModel.isSpendOnWater {
                        Button(action: {
                            viewModel.showEndTimePicker.toggle()
                        }) {
                            HStack {
                                Text(viewModel.formattedTime(viewModel.selectedEndTime, placeholder: "Select End Time"))
                                Spacer()
                                Image(systemName: "clock.fill")
                            }
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                        }
                        .padding(.horizontal)

                        if let start = viewModel.selectedStartTime,
                           let end = viewModel.selectedEndTime {
                            Text("Duration: \(viewModel.timeDifference(from: start, to: end))")
                                .padding(.horizontal)
                        }
                    }

                    Spacer()

                    Button(action: {
                        viewModel.saveAndProceed(using: uiFlowState)
                    }) {
                        Text("Next")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)

                    NavigationLink(
                        destination: VoyagerRateView(
                            dependencies: dependencies,
                            onSponsorsSelected: { _ in },
                            isSpendOnWater: viewModel.isSpendOnWater
                        ),
                        isActive: $viewModel.moveToNextScreen
                    ) { EmptyView() }
                }
            }

            if viewModel.showCalendar {
                DatePicker("", selection: Binding($viewModel.selectedDate, replacingNilWith: Date()), displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(10)
                    .shadow(radius: 5)
                    .padding()
                    .onChange(of: viewModel.selectedDate) { _, _ in
                        viewModel.showCalendar = false
                    }
            }

            if viewModel.showStartTimePicker {
                DatePicker("Select Start Time", selection: Binding($viewModel.selectedStartTime, replacingNilWith: Date()), displayedComponents: .hourAndMinute)
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .padding()
                    .background(Color.white)
                    .cornerRadius(10)
                    .shadow(radius: 5)
                    .padding()
                    .onChange(of: viewModel.selectedStartTime) { _, _ in
                        viewModel.showStartTimePicker = false
                    }
            }

            if viewModel.isSpendOnWater, viewModel.showEndTimePicker {
                DatePicker("Select End Time", selection: Binding($viewModel.selectedEndTime, replacingNilWith: Date()), displayedComponents: .hourAndMinute)
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .padding()
                    .background(Color.white)
                    .cornerRadius(10)
                    .shadow(radius: 5)
                    .padding()
                    .onChange(of: viewModel.selectedEndTime) { _, _ in
                        viewModel.showEndTimePicker = false
                    }
            }
        }
        .overlay(
            ToastView(message: viewModel.toastMessage, isPresented: $viewModel.showToast)
        )
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden)
    }
}






// MARK: - Binding Helper for Optional Values
extension Binding where Value: Equatable {
    init(_ source: Binding<Value?>, replacingNilWith defaultValue: Value) {
        self.init(
            get: { source.wrappedValue ?? defaultValue },
            set: { source.wrappedValue = $0 }
        )
    }
}




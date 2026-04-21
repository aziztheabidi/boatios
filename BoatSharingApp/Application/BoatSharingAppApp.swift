//
//  BoatSharingAppApp.swift
//  BoatSharingApp
//
//  Created by HOM3 on 27/01/2025.
//

import SwiftUI
import Firebase

final class AppState: ObservableObject {
    private let preferences: PreferenceStoring
    private let sessionManager: SessionManaging
    @Published var isLoggedIn: Bool
    @Published var userRole: String
    @Published var missingStep: Int

    init(preferences: PreferenceStoring, sessionManager: SessionManaging) {
        self.preferences = preferences
        self.sessionManager = sessionManager
        self.isLoggedIn = preferences.isLoggedIn && sessionManager.hasValidSession()
        self.userRole = preferences.userRole
        self.missingStep = preferences.missingStep
    }

    func syncFromStorage() {
        isLoggedIn = preferences.isLoggedIn && sessionManager.hasValidSession()
        userRole = preferences.userRole
        missingStep = preferences.missingStep
    }
}

extension AppState: RoutableAppState {}

@main
struct BoatSharingAppApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var appState: AppState
    @StateObject var uiFlowState = UIFlowState()
    private let dependencies: AppDependencies

    init() {
        AppServices.configure()
        let dependencies = AppDependencies.live
        self.dependencies = dependencies
        AppSessionSnapshot.configure(dependencies.sessionPreferences)
        _appState = StateObject(
            wrappedValue: AppState(
                preferences: dependencies.preferences,
                sessionManager: dependencies.sessionManager
            )
        )
    }

    var body: some Scene {
        WindowGroup {
            ContentView1()
                .environmentObject(appState)
                .environmentObject(uiFlowState)
                .onAppear {
                    dependencies.routingNotifier.bind(appState)
                }
        }
    }
}

struct ContentView1: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        NavigationStack {
            if appState.isLoggedIn {
                switch appState.userRole {
                case "Voyager":
                    if appState.missingStep == 0 {
                        VoyagerHomeView()
                    } else {
                        RoleSelectionView()
                    }
                case "Captain":
                    if appState.missingStep == 0 {
                        CaptainHomeVC()
                    } else {
                        RoleSelectionView()
                    }
                default:
                    if appState.missingStep == 0 {
                        DashboardVC()
                    } else {
                        RoleSelectionView()
                    }
                }
            } else {
                SplashScreenView()
                    .navigationBarBackButtonHidden(true)
            }
        }
        .onAppear(perform: syncRoutingStateFromStorage)
        .onChange(of: appState.isLoggedIn) { _, _ in
            syncRoutingStateFromStorage()
        }
    }

    private func syncRoutingStateFromStorage() {
        appState.syncFromStorage()
    }
}

//
//  BoatSharingAppApp.swift
//  BoatSharingApp
//
//  Created by HOM3 on 27/01/2025.
//

import SwiftUI
import Firebase
import Combine

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
        _appState = StateObject(
            wrappedValue: AppState(
                preferences: dependencies.preferences,
                sessionManager: dependencies.sessionManager
            )
        )
    }

    var body: some Scene {
        WindowGroup {
            ContentView1(dependencies: dependencies)
                .environmentObject(appState)
                .environmentObject(uiFlowState)
                .onAppear {
                    dependencies.routingNotifier.bind(appState)
                    uiFlowState.resetTransientFlags()
                }
        }
    }
}

struct ContentView1: View {
    private let dependencies: AppDependencies
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var uiFlowState: UIFlowState

    init(dependencies: AppDependencies) {
        self.dependencies = dependencies
    }

    var body: some View {
        NavigationStack {
            if appState.isLoggedIn {
                switch appState.userRole {
                case "Voyager":
                    if appState.missingStep == 0 {
                        VoyagerHomeView(dependencies: dependencies)
                    } else {
                        RoleSelectionView(dependencies: dependencies)
                    }
                case "Captain":
                    if appState.missingStep == 0 {
                        CaptainHomeVC(dependencies: dependencies)
                    } else {
                        RoleSelectionView(dependencies: dependencies)
                    }
                default:
                    if appState.missingStep == 0 {
                        DashboardVC(dependencies: dependencies)
                    } else {
                        RoleSelectionView(dependencies: dependencies)
                    }
                }
            } else {
                SplashScreenView(dependencies: dependencies)
                    .navigationBarBackButtonHidden(true)
            }
        }
        .onChange(of: appState.isLoggedIn) { _, loggedIn in
            appState.syncFromStorage()
            if !loggedIn {
                uiFlowState.resetAfterLogout()
            }
        }
    }
}


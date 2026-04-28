//
//  LocationManager.swift
//  BoatSharingApp
//
//  Created by Gamex Global on 05/03/2025.
//
import Firebase
import FirebaseFirestore
import CoreLocation

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    private let db = Firestore.firestore()
    /// When non-nil, location updates are mirrored to Firestore under this user's document.
    private let sessionPreferences: SessionPreferenceStoring?
    @Published var currentLocation: CLLocationCoordinate2D?

    init(sessionPreferences: SessionPreferenceStoring? = nil) {
        self.sessionPreferences = sessionPreferences
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestAlwaysAuthorization()
        locationManager.requestLocation()
    }
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    }
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        let coordinate = location.coordinate
        Task { @MainActor [weak self] in
            guard let self else { return }
            self.currentLocation = coordinate
            self.startUpdatingLocationToFirebase()
        }
    }

    func startUpdatingLocationToFirebase() {
        updateLocationInFirebase()
    }

    func updateLocationInFirebase() {
        guard let sessionPreferences else { return }
        guard let location = currentLocation else { return }
        let userId = sessionPreferences.userID.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !userId.isEmpty else { return }

        let locationData: [String: Any] = [
            "latitude": location.latitude,
            "longitude": location.longitude,
            "timestamp": Timestamp(date: Date())
        ]
        
        db.collection("locations").document(userId).setData(locationData) { error in
            if let error = error {
            } else {
            }
        }
    }
}

//
//  LocationService.swift
//  SoundSpots
//
//  Wraps CLLocationManager's delegate callbacks in a simple completion-handler API.
//

import CoreLocation

enum LocationError: LocalizedError {
    case permissionDenied
    case unavailable(Error?)

    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Location access is off. You can turn it on in Settings › Privacy › Location Services."
        case .unavailable:
            return "Your location couldn't be determined right now."
        }
    }
}

final class LocationService: NSObject {

    private let manager = CLLocationManager()
    private let geocoder = CLGeocoder()

    /// Completion handlers waiting for a location fix. They are stored, so they must be @escaping.
    private var pendingRequests: [(Result<CLLocation, LocationError>) -> Void] = []

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    /// Asks for permission if needed, then reports a single location.
    func requestCurrentLocation(completion: @escaping (Result<CLLocation, LocationError>) -> Void) {
        pendingRequests.append(completion)

        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()   // answer arrives in the delegate below
        case .denied, .restricted:
            finish(with: .failure(.permissionDenied))
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()
        @unknown default:
            finish(with: .failure(.unavailable(nil)))
        }
    }

    /// Turns a coordinate into a friendly name like "Blue Bottle Coffee" or "Mission District".
    func placeName(for location: CLLocation, completion: @escaping (String?) -> Void) {
        geocoder.reverseGeocodeLocation(location) { placemarks, _ in
            let placemark = placemarks?.first
            let name = placemark?.name ?? placemark?.subLocality ?? placemark?.locality
            DispatchQueue.main.async { completion(name) }
        }
    }

    private func finish(with result: Result<CLLocation, LocationError>) {
        let callbacks = pendingRequests
        pendingRequests.removeAll()
        DispatchQueue.main.async {
            callbacks.forEach { $0(result) }
        }
    }
}

// MARK: - CLLocationManagerDelegate (a protocol from CoreLocation)

extension LocationService: CLLocationManagerDelegate {

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        guard !pendingRequests.isEmpty else { return }
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()
        case .denied, .restricted:
            finish(with: .failure(.permissionDenied))
        default:
            break   // still waiting for the user to answer the prompt
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        finish(with: .success(location))
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        finish(with: .failure(.unavailable(error)))
    }
}

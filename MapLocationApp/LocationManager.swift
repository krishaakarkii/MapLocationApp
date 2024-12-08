import Foundation
import CoreLocation

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private var locationManager = CLLocationManager()
    
    @Published var location: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var locationAccessDenied = false

    override init() {
        super.init()
        locationManager.delegate = self
        requestLocationPermission()
    }
    
    func requestLocationPermission() {
        print("Requesting location permission")
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        DispatchQueue.main.async {
            if let newLocation = locations.last {
                print("Location updated: \(newLocation.coordinate.latitude), \(newLocation.coordinate.longitude)")
                self.location = newLocation
            } else {
                print("Location update received but no valid location.")
            }
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        self.authorizationStatus = manager.authorizationStatus
        switch authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            print("Location access authorized")
            locationManager.startUpdatingLocation()
            locationAccessDenied = false
        case .denied, .restricted:
            print("Location access denied")
            locationAccessDenied = true
        default:
            print("Location access status not determined")
            break
        }
    }
}


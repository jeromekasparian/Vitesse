//
//  LocationManager.swift
//  Vitesse watch Watch App
//
//  Created by Jérôme Kasparian on 22/09/2026.
//
// https://www.createwithswift.com/updating-the-users-location-with-core-location-and-swift-concurrency-in-swiftui/

import Foundation
import CoreLocation

class LocationManager: NSObject, CLLocationManagerDelegate {
    //MARK: Object to Access Location Services
    private let locationManager = CLLocationManager()
    var locationToujoursAutorisee: Bool = false
    
    //MARK: Continuation Object for the User Location
    private var continuation: CheckedContinuation<CLLocation, Error>?

    //MARK: Set up the Location Manager Delegate
    override init() {
        super.init()
        locationManager.delegate = self
        self.locationToujoursAutorisee = gereDroitsLocalisation()
    }

    // Error messages associated with the location manager
    enum LocationManagerError: String, Error {
        case replaceContinuation = "Continuation replaced."
        case locationNotFound = "No location found."
    }
    
    //MARK: Asynchronously request the current location
    var currentLocation: CLLocation {
        get async throws {
            // Check if there is a continuation being worked on
            if self.continuation != nil {
                // If so, resumes it throwing an error
                self.continuation?.resume(throwing: LocationManagerError.replaceContinuation)
                // And deletes it, so a new one can be created
                self.continuation = nil
            }
        
            return try await withCheckedThrowingContinuation { continuation in
                // 1. Set up the continuation object
                self.continuation = continuation
                // 2. Triggers the update of the current location
                locationManager.requestLocation()
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
         // 4. If there is a location available
         if let lastLocation = locations.last {
             // 5. Resumes the continuation object with the user location as result
             continuation?.resume(returning: lastLocation)
             // Resets the continuation object
             continuation = nil
         } else {
             // If there is no location, resumes the continuation throwing and error to avoid a continuation leak
             continuation?.resume(throwing: LocationManagerError.locationNotFound)
         }
     }
     
     func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
         // 6. If not possible to retrieve a location, resumes with an error
         continuation?.resume(throwing: error)
         // Resets the continuation object
         continuation = nil
     }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        self.locationToujoursAutorisee = gereDroitsLocalisation()
    }

    func gereDroitsLocalisation() -> Bool {
//        print("droits de localisation : ", CLLocationManager.authorizationStatus().toText())
        self.locationManager.requestAlwaysAuthorization()
        let statut = CLLocationManager.authorizationStatus()
        switch statut {
        case .authorizedAlways, .authorizedWhenInUse:  // l'app a l'autorisation d'accéder à la localisation
            self.locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
            if statut == .authorizedAlways {
                self.locationManager.allowsBackgroundLocationUpdates = true
                self.locationManager.activityType = .otherNavigation
            }
            self.locationManager.startUpdatingLocation()

            return statut == .authorizedAlways
        case .denied, .restricted:
            return false

        case .notDetermined:
            print("not determined")
            return false
        default:
            print("défaut")
            return false
        } // switch

    }
        

}

//
//  ExtensionCLAuthorizationStatus.swift
//  Vitesse
//
//  Created by Jérôme Kasparian on 28/06/2026.
//

import Foundation
import CoreLocation

extension CLAuthorizationStatus {
    func toText() -> String {
        switch self {
            case .authorizedAlways:
            return "authorizedAlways"
        case .authorizedWhenInUse:
            return "authorizedWhenInUse"
        case .denied:
            return "denied"
        case .notDetermined:
            return "notDetermined"
        case .restricted:
            return "restricted"
        @unknown default:
            return "unknown default"
        }
    }
}

//
//  ExtensionCLLocation.swift
//  Vitesse
//
//  Created by Jérôme Kasparian on 07/02/2026.
//

import Foundation
import CoreLocation

let decalagePourCalculePente: Double = 10.0 // m
extension CLLocation {

    func decale(distance: Double, azimut: Double) -> CLLocation { // approximation planaire locale
        let distanceEnDegres = distance / 111000.0
        let azimutRadians = azimut * degresEnRadians
        let latitudeDecalee = self.coordinate.latitude + distanceEnDegres * cos(azimutRadians)
        let longitudeDecalee = self.coordinate.longitude + distanceEnDegres * sin(azimutRadians) / cos(self.coordinate.latitude * degresEnRadians)
        return CLLocation(latitude: latitudeDecalee, longitude: longitudeDecalee)
    }
        
    func penteDeOpenTopoData() async -> (Double, String) {
        guard self.speed > 1.0 && self.speedAccuracy >= 0 && self.courseAccuracy >= 0 && self.course >= 0 && self.course < 360 else {
            return (.nan, "guard")
        }
        let pointDevant = self.decale(distance: decalagePourCalculePente, azimut: self.course)
        let pointDerriere = self.decale(distance: -decalagePourCalculePente, azimut: self.course)
        let texteURL = "https://api.opentopodata.org/v1/eudem25m?locations=%f,%f%%7C%f,%f%%7C"
        let texteURLComplet = String(format: texteURL, pointDerriere.coordinate.latitude, pointDerriere.coordinate.longitude, pointDevant.coordinate.latitude, pointDevant.coordinate.longitude)
        if let urlDEM = URL(string: texteURLComplet) {
            do {
                let (data, _) = try await URLSession.shared.data(from: urlDEM)
                let texte = String(data: data, encoding: .utf8) ?? ""
                let statutOK = texte.contains("\"status\": \"OK\"")
                if statutOK {
                    let elements = texte.components(separatedBy: "\"elevation\": ").dropFirst(1)
                    guard elements.count >= 2 else {
                        print("Pas assez d'éléments")
                        return (.nan, texte)
                    }
                    var altitudes: [Double] = []
                    for element in elements {
                        let nombre = element.components(separatedBy: ",").first ?? ""
                        let altitude = Double(nombre) ?? self.altitude
                        altitudes.append(altitude)
                    }
                    return ((altitudes[1] - altitudes[0]) / (decalagePourCalculePente * 2.0), String(format: "%.2f, %.2f", altitudes[1], altitudes[0]))
                } else {
                    print("statut pas ok")
                    return (.nan, "statut")
                }
            } catch {
                print("Erreur de lecture de l'altitude")
                return (.nan, "lecture")
            }

        } else {
            return (.nan, texteURLComplet)
        }
    }
    
}

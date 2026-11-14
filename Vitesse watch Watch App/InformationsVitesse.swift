//
//  InformationsVitesse.swift
//  Vitesse watch Watch App
//
//  Created by Jérôme Kasparian on 20/09/2026.
//

import Foundation
import SwiftUI
public import Combine
import CoreLocation

class InformationsVitesse: ObservableObject {


    @Published var vitesse: Double = .nan
    @Published var texteUniteVitesse: String = "km/h"
    @Published var texteUniteDistance: String = "km"
    @Published var texteUniteAltitude: String = "m"
    @Published var facteurUniteVitesse: Double = 1.0
    @Published var facteurUniteDistance: Double = 1.0
    @Published var facteurUniteAltitude: Double = 1.0
    @AppStorage(keyVitesseMax) private var vitesseMax: Double = 0.0
    @AppStorage(keyDistanceTotale) private var distanceTotale: Double = 0.0
    @Published var dejaEuUneVitesse: Bool = false
    
    var stats = Stats()
    var unite: Int = 1
    var compteur: Int = 0
    var nombrePositionsLues: Int = 0
    var locationPrecedente: CLLocation?
    var altitude10: Double = .nan
    var position10: Double = .nan
    var altitudePrecedente10: Double = .nan
    var positionPrecedente10: Double = .nan
    var userDefaults = UserDefaults.standard

    var timer = Timer()
    var locationManager = LocationManager()

    init() {
        stats.vitesseMax = vitesseMax //userDefaults.value(forKey: keyVitesseMax) as? Double ?? 0.0
        stats.distanceTotale = distanceTotale //userDefaults.value(forKey: keyDistanceTotale) as? Double ?? 0.0

        unite = userDefaults.value(forKey: keyUnite) as? Int ?? unite
        reglageUnite(unite: unite)

        self.timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task{
                await self.nouvelleLocalisation()
            }
        }
    }

    // TODO voir s'il faut filtrer le comportement au repos, comme sur iOS 27 sur iPhone
    func nouvelleLocalisation() async {
        do {
            let location = try await self.locationManager.currentLocation
            // au-delà de 12 heures en arrière-plan, on réinitialise le trajet
            if location.timestamp.timeIntervalSince(locationPrecedente?.timestamp ?? Date(timeIntervalSince1970: 0.0)) > tempsAvantReinitialisationAuto {
                stats.effacerSession()
            }
            nombrePositionsLues = nombrePositionsLues + 1
            let directionOK = location.course >= 0 || (location.speed >= 0 && location.speed < 1)
            let pasTunnelLong = location.timestamp.timeIntervalSince(locationPrecedente?.timestamp ?? Date(timeIntervalSince1970: 0.0)) < dureeMaxiTunnel
            let localisationsNombreusesOuPrecises = nombrePositionsLues >= nbPositionsMiniAuDemarrage || location.horizontalAccuracy <= 10
            let deplacementDepuisDernierePosition = locationPrecedente?.distance(from: location) ?? 0.0
            let deplacementSelonVitesse = location.speed * location.timestamp.timeIntervalSince(locationPrecedente?.timestamp ?? Date(timeIntervalSince1970: 0))
            let ratioDeplacements = deplacementSelonVitesse / deplacementDepuisDernierePosition
            let deplacementVraisemblable = ratioDeplacements > 0.67 || ratioDeplacements < 1.5
            let vitesseOKPourAffichage = directionOK && pasTunnelLong && localisationsNombreusesOuPrecises && location.courseAccuracy >= 0 && location.speedAccuracy >= 0
            let vitesseOKPourStats = vitesseOKPourAffichage && deplacementVraisemblable
            
            if location.verticalAccuracy <= precisionVerticaleMinimale && location.verticalAccuracy >= 0.0 && !location.altitude.isNaN {
                altitude10 = stats.moyenneGlissanteAltitude10.actualiser(location.altitude)
                position10 = stats.moyenneGlissantePosition10.actualiser(stats.distanceTotaleSession)
            }

            guard vitesseOKPourAffichage else {
                self.vitesse = .nan
                locationPrecedente = location
                return
            }
            self.vitesse = location.speed
            dejaEuUneVitesse = true
            
            guard vitesseOKPourStats && location.speed > vitesseMiniPourActiverCompteur && locationPrecedente != nil else {
                locationPrecedente = location
                return
            }
            stats.distanceTotale = stats.distanceTotale + deplacementDepuisDernierePosition
            distanceTotale = stats.distanceTotale
            stats.distanceTotaleSession = stats.distanceTotaleSession + deplacementDepuisDernierePosition
            stats.distanceTotale = max(stats.distanceTotale, stats.distanceTotaleSession)
            stats.tempsSession = stats.tempsSession + location.timestamp.timeIntervalSince(locationPrecedente!.timestamp)
            if location.speed > stats.vitesseMax {
                stats.vitesseMax = location.speed
                vitesseMax = stats.vitesseMax
                }
            if location.speed > stats.vitesseMaxSession {
                stats.vitesseMaxSession = location.speed
            }
            if location.verticalAccuracy <= precisionVerticaleMinimale && location.verticalAccuracy >= 0.0 && !location.altitude.isNaN {
                let d = position10 - positionPrecedente10
                let denivele = altitude10 - altitudePrecedente10
                let pente = denivele / d
                let nombrePointsOK = stats.moyenneGlissanteAltitude10.valeurStable()
                if abs(pente) <= penteMaximaleCredible && nombrePointsOK {
                    if denivele >= 0 {
                        stats.denivelePositifSession = stats.denivelePositifSession + denivele
                    } else {
                        stats.deniveleNegatifSession = stats.deniveleNegatifSession - denivele
                    }
                }
                altitudePrecedente10 = altitude10.isNaN ? altitudePrecedente10 : altitude10
                positionPrecedente10 = position10.isNaN ? positionPrecedente10 : position10

            }
            
            locationPrecedente = location

        } catch {
            self.vitesse = .nan
            print("vitesse invalide")
        }
    }
    
    func incremente() {
        compteur = compteur + 1
        vitesse = Double(compteur) * facteurUnitesVitesses[unite]
    }
    
    func changeUnite() {
        unite = (unite + 1) % textesUnites.count
        userDefaults.set(unite, forKey: keyUnite)
        reglageUnite(unite: unite)
    }
    
    func reglageUnite(unite: Int){
        guard unite < textesUnites.count else {return}
        texteUniteVitesse = textesUnites[unite]
        texteUniteDistance = textesUnitesDistance[unite]
        texteUniteAltitude = textesUnitesAltitude[unite]
        facteurUniteDistance = facteurUnitesDistance[unite]
        facteurUniteVitesse = facteurUnitesVitesses[unite]
        facteurUniteAltitude = facteurUnitesAltitude[unite]
    }
    

    
    @MainActor
    deinit {
        timer.invalidate()
    }
    
}

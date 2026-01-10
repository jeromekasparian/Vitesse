//
//  Stats.swift
//  Vitesse
//
//  Created by Jérôme Kasparian on 09/01/2026.
//

import Foundation
class Stats {
    var vitesseMax = 0.0
    var vitesseMaxSession = 0.0
    var distanceTotale = 0.0
    var distanceTotaleSession = 0.0
    var denivelePositifSession = 0.0
    var deniveleNegatifSession = 0.0
    var tempsSession = 0.0
    
    func effacerSession() {
        self.distanceTotaleSession = 0.0
        self.vitesseMaxSession = 0.0
        self.denivelePositifSession = 0.0
        self.deniveleNegatifSession = 0.0
        self.tempsSession = 0.0
//        NotificationCenter.default.post(name : Notification.Name(notificationMiseAJourStats),object: nil)  // on prévient le ViewController d'actualiser l'affichage et d'enregistrer
    }
    
    func effacerTout() {
        vitesseMax = 0.0
        distanceTotale = 0.0
        self.effacerSession()
    }
}

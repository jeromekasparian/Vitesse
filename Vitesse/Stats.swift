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
//    let moyenneGlissanteAltitude8 = MoyenneGlissante(nombrePointsAMoyenner: 8)
    let moyenneGlissanteAltitude10 = MoyenneGlissante(nombrePointsAMoyenner: 10)
//    let moyenneGlissanteAltitude15 = MoyenneGlissante(nombrePointsAMoyenner: 15)
//    let moyenneGlissanteDistance8 = MoyenneGlissante(nombrePointsAMoyenner: 8)
    let moyenneGlissanteDistance10 = MoyenneGlissante(nombrePointsAMoyenner: 10)
//    let moyenneGlissanteDistance15 = MoyenneGlissante(nombrePointsAMoyenner: 15)
    let moyenneGlissanteDenivele10 = MoyenneGlissante(nombrePointsAMoyenner: 10)
    let moyenneGlissantePosition10 = MoyenneGlissante(nombrePointsAMoyenner: 10)
    
    func effacerSession() {
        self.distanceTotaleSession = 0.0
        self.vitesseMaxSession = 0.0
        self.denivelePositifSession = 0.0
        self.deniveleNegatifSession = 0.0
        self.tempsSession = 0.0
//        self.moyenneGlissanteAltitude8.reset()
        self.moyenneGlissanteAltitude10.reset()
//        self.moyenneGlissanteAltitude15.reset()
//        self.moyenneGlissanteDistance8.reset()
        self.moyenneGlissanteDistance10.reset()
//        self.moyenneGlissanteDistance15.reset()
        self.moyenneGlissanteDenivele10.reset()
        self.moyenneGlissantePosition10.reset()
    }
    
    func effacerTout() {
        vitesseMax = 0.0
        distanceTotale = 0.0
        self.effacerSession()
    }
}

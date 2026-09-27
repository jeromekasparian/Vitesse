//
//  Stats.swift
//  Vitesse
//
//  Created by Jérôme Kasparian on 09/01/2026.
//

import Foundation
import SwiftUI

internal import Combine
class Stats {
    @Published var vitesseMax = 0.0
    @Published var vitesseMaxSession = 0.0
    @Published var distanceTotale = 0.0
    @Published var distanceTotaleSession = 0.0
    @Published var denivelePositifSession = 0.0
    @Published var deniveleNegatifSession = 0.0
    
    var tempsSession = 0.0
    let moyenneGlissanteAltitude10 = MoyenneGlissante(nombrePointsAMoyenner: 10)
    let moyenneGlissanteDistance10 = MoyenneGlissante(nombrePointsAMoyenner: 10)
    let moyenneGlissanteDenivele10 = MoyenneGlissante(nombrePointsAMoyenner: 10)
    let moyenneGlissantePosition10 = MoyenneGlissante(nombrePointsAMoyenner: 10)
    
    func effacerSession() {
        self.distanceTotaleSession = 0.0
        self.vitesseMaxSession = 0.0
        self.denivelePositifSession = 0.0
        self.deniveleNegatifSession = 0.0
        self.tempsSession = 0.0
        self.moyenneGlissanteAltitude10.reset()
        self.moyenneGlissanteDistance10.reset()
        self.moyenneGlissanteDenivele10.reset()
        self.moyenneGlissantePosition10.reset()
    }
    
    func effacerTout() {
        vitesseMax = 0.0
        distanceTotale = 0.0
        self.effacerSession()
    }
}

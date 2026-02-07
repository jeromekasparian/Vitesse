//
//  Totaliseur.swift
//  Vitesse
//
//  Created by Jérôme Kasparian on 30/01/2026.
//

import Foundation

class MoyenneGlissante {
    private final var nombreAMoyenner: Int
    var valeurActuelle: Double = 0
    
    init(nombreAMoyenner: Int) {
        self.nombreAMoyenner = nombreAMoyenner
        self.valeurActuelle = 0
    }
    
    func ajouter(_ nouvelleValeur: Double) {
        valeurActuelle = (valeurActuelle * Double(nombreAMoyenner - 1)) + nouvelleValeur
        valeurActuelle /= Double(nombreAMoyenner)
    }
}

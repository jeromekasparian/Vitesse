//
//  Totaliseur.swift
//  Vitesse
//
//  Created by Jérôme Kasparian on 30/01/2026.
//

import Foundation

class MoyenneGlissante {
    private final var nombrePointsAMoyenner: Int
    private var valeurActuelle: Double
    private var nombreValeurs: Int
    
    init(nombrePointsAMoyenner: Int) {
        self.nombrePointsAMoyenner = max(1, nombrePointsAMoyenner)
        self.valeurActuelle = .nan
        self.nombreValeurs = 0
    }

    func reset() {
        self.valeurActuelle = .nan
        self.nombreValeurs = 0
    }
    
    func valeurStable() -> Bool {
        return self.nombreValeurs >= nombrePointsAMoyenner
    }


    func actualiser(_ nouvelleValeur: Double) -> Double {
        if valeurActuelle.isNaN {
            valeurActuelle = nouvelleValeur
            nombreValeurs = 1
        } else if nombreValeurs <= nombrePointsAMoyenner {
            valeurActuelle = (nouvelleValeur + (valeurActuelle * Double(nombreValeurs))) / Double(nombreValeurs + 1)
            nombreValeurs = nombreValeurs + 1
        } else {
            valeurActuelle = (nouvelleValeur + (valeurActuelle * Double(nombrePointsAMoyenner - 1))) / Double(nombrePointsAMoyenner)
            nombreValeurs = nombreValeurs + 1
        }
        return valeurActuelle
    }
}

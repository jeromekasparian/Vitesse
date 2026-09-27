//
//  Constantes.swift
//  Vitesse
//
//  Created by Jérôme Kasparian on 26/09/2026.
//

import Foundation

let keyUnite = "uniteAuDemarrage"
let keyVitesseMax = "vitesseMax"
let keyDistanceTotale = "distanceTotale"
let keyAutoriserAffichageTeteHaute = "autoriserAffichageTeteHaute"
//let notificationMiseAJourStats = "miseAJourStats"
let keyEnregistrerStats = "keyEnregistrerStats"
let keyMontrerAlerteDemarrage = "keyMontrerAlerteDemarrage"
let keyStatsInBackground = "keyStatsInBackground"
let keyAlerteLocationToujoursDejaAffichee = "keyAlerteLocationToujoursDejaAffichee"
//let keyMontrerAlertePasLocalisationEnBackground = "keyMontrerAlertePasLocalisationEnBackground"
let nomSegueOuvreStats = "OuvreStats"

let precisionVerticaleMinimale: Double = 10.0 // précision minimale sur l'altitude pour qu'on la prenne en compte
let precisionHorizontaleMinimalePourAltitudeOpenTopo: Double = 10.0 // m
let textesUnites: [String] = [NSLocalizedString("m/s", comment: "vistesse : m/s"), NSLocalizedString("km/h", comment: "vitesse : km/h"), NSLocalizedString("mph", comment: "vitesse : mph"), NSLocalizedString("kt", comment: "vitesse : nœuds")]
let textesUnitesDistance: [String] = [NSLocalizedString("km", comment: "distance : m"), NSLocalizedString("km", comment: "distance : km"), NSLocalizedString("mi", comment: "distance : mi"), NSLocalizedString("nm", comment: "distance : miles nautiques")]
let textesUnitesAltitude: [String] = [" " + NSLocalizedString("m", comment: "m"), " " + NSLocalizedString("m", comment: "m"), NSLocalizedString("'", comment: "pied") + " ", NSLocalizedString("'", comment: "pied") + " "]

let facteurUnitesVitesses: [Double] = [1.0, 3.6, 2.2369362920544, 1.94552529]
let facteurUnitesDistance: [Double] = [0.001, 0.001, 0.00062137, 0.00053996]
let facteurUnitesAltitude: [Double] = [1.0, 1.0, 3.2808, 3.2808]

// le temps total de trajet, en secondes
let penteMaximaleCredible: Double = 0.3
let penteMinimalePourAffichage: Double = 0.02
let distanceMiniPourPente: Double = 0.3

let radiansEnDegres = 180.0 / 3.14159
let degresEnRadians = Double.pi / 180.0
let pointsPourPente: Int = 10

let tempsMaxEntrePositions = 5.0 // temps en secondes au-delà duquel on considère qu'on a perdu la position
let nbPositionsMiniAuDemarrage = 5 // nombre de positions qu'on lit avant de les prendre en compte.
let tempsAvantReinitialisationAuto: Double = 3600 * 12 // temps en secondes au-delà duquel on réinitialise les stats de trajet
let vitesseMiniPourActiverCompteur = 0.2 // m/s : vitesse en-dessous de laquelle on considère qu'on est immobile
let dureeMaxiTunnel: Double = 3600 // secondes : temps maxi pendant lequel on peut perdre la localisation et, à l'arriver, incrémenter la distance, la durée et le dénivelé.

//
//  Stats.swift
//  Vitesse watch Watch App
//
//  Created by Jérôme Kasparian on 26/09/2026.
//

import SwiftUI

struct StatsViewWatch: View {
//    @StateObject private var informations = InformationsVitesse()
    @EnvironmentObject var informations: InformationsVitesse

    var body: some View {
        VStack{
            Color.black
            let distanceTotale = informations.stats.distanceTotale * informations.facteurUniteDistance
            let format = distanceTotale >= 100.0 ? " %.0f" : " %.1f"
            HStack {
                Text(NSLocalizedString("Total", comment: "") + String(format: format, distanceTotale) + informations.texteUniteDistance)
                    .font(Font.monospacedDigit(Font.callout)().bold())
                Spacer()
                Button("", systemImage: "delete.left", action: {
                    informations.stats.effacerTout()
                })
                .buttonStyle(.plain)
            }
            Text(NSLocalizedString("Max ", comment: "") + String(format: "%.0f ", informations.stats.vitesseMax * informations.facteurUniteVitesse) + informations.texteUniteVitesse)
                .font(Font.monospacedDigit(Font.callout)())
            Spacer(minLength: 8.0)
            let minutesTot = Int(informations.stats.tempsSession) / 60
            let minutes = minutesTot % 60
            let heures = minutesTot / 60
            let message = heures > 0 ? String(format:NSLocalizedString("Trajet (%d h %d min", comment: "") + ")", heures, minutes) : String(format:NSLocalizedString("Trajet (%d min", comment: "") + ")", minutes)
            HStack {
                Text(message)
                    .font(Font.monospacedDigit(Font.callout)().bold())
                Spacer()
                Button("", systemImage: "delete.left", action: {
                    informations.stats.effacerSession()
                })
                .buttonStyle(.plain)
            }
            Text(NSLocalizedString("Max ", comment: "") + String(format: "%.0f ", informations.stats.vitesseMaxSession * informations.facteurUniteVitesse) + informations.texteUniteVitesse)
                .font(Font.monospacedDigit(Font.callout)())
            Text(String(format: "%.1f " + informations.texteUniteDistance, informations.stats.distanceTotaleSession * informations.facteurUniteDistance))
                .font(Font.monospacedDigit(Font.callout)())
            let messageDenivele = texteAffichageValeur(prefixe: "➚ ", format: "%4.0f", valeur: informations.stats.denivelePositifSession * informations.facteurUniteAltitude, unite: informations.texteUniteAltitude) + " " + texteAffichageValeur(prefixe: "➘ ", format: "%4.0f", valeur: informations.stats.deniveleNegatifSession * informations.facteurUniteAltitude, unite: informations.texteUniteAltitude)
            Text(messageDenivele)
                .font(Font.monospacedDigit(Font.callout)())
        } // VStack
    } // body
    
    func texteAffichageValeur(prefixe: String, format: String, valeur: Double, unite: String) -> String {
        return prefixe + String(format: format, valeur).replacingOccurrences(of: " ", with: "\u{2007}") + " " + unite  // .replacingOccurrences(of: " ", with: "\u{2007}")
    }

} // struct

    
#Preview {
    StatsViewWatch()
}


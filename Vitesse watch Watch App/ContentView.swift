//
//  ContentView.swift
//  Vitesse watch Watch App
//
//  Created by Jérôme Kasparian on 23/06/2026.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var informations: InformationsVitesse
    var body: some View {
            ZStack {
                ZStack() {
                    Color.black
                        .ignoresSafeArea(edges: .all)
                    if !informations.dejaEuUneVitesse {
                        ProgressView()
                    } else if informations.vitesse.isNaN {
                        Image(systemName: "location.slash.fill")
                            .resizable()
                            .scaledToFit()
                            .symbolRenderingMode(.hierarchical)
                            .foregroundColor(.gray)
                    }
                    let vitesse = informations.vitesse.isNaN ? -1 : Int(informations.vitesse * informations.facteurUniteVitesse)
                    let texte = vitesse < 0 ? "??" : (vitesse < 10 ? "\u{2007}" : "") + String(format: "%d", vitesse)
                    if !informations.vitesse.isNaN {
                        Text(texte)
                            .padding(1)
                            .font(Font.monospacedDigit(Font.system(size: 1000))())
                            .minimumScaleFactor(0.01)
                            .foregroundColor(Color(UIColor.lightGray))
                            .background(Color.black)
                            .multilineTextAlignment(.center)
                        //                    .hiddenConditionally(isHidden: informations.vitesse.isNaN)
                    }
                    
                    VStack() {
                        Spacer()
                        HStack() {
                            Spacer()
                            Button(informations.texteUniteVitesse, action: {informations.changeUnite()})
                                .buttonStyle(.plain)
                                .font(Font.body)
                                .foregroundColor(Color(UIColor.lightGray))
                                .background(Color.black)
                        } // HStack
                    } // VStack
                } // ZStack
            } // Zstack
//            .tabItem{
//                Label("Vitesse", systemImage: "numbers")
//            }
            
//            VStack{
//                Color.black
//                Text(NSLocalizedString("Total", comment: "") + String(format: " %.0f ", informations.stats.distanceTotale * informations.facteurUniteDistance) + informations.texteUniteDistance)
//                    .font(Font.monospacedDigit(Font.callout)().bold())
//                Text(NSLocalizedString("Max ", comment: "") + String(format: "%.0f ", informations.stats.vitesseMax * informations.facteurUniteVitesse) + informations.texteUniteVitesse)
//                    .font(Font.monospacedDigit(Font.callout)())
//                Spacer(minLength: 8.0)
//                let minutesTot = Int(informations.stats.tempsSession) / 60
//                let minutes = minutesTot % 60
//                let heures = minutesTot / 60
//                let message = heures > 0 ? String(format:NSLocalizedString("Trajet (%d h %d min", comment: "") + ")", heures, minutes) : String(format:NSLocalizedString("Trajet (%d min", comment: "") + ")", minutes)
//                Text(message)
//                    .font(Font.monospacedDigit(Font.callout)().bold())
//                    Text(NSLocalizedString("Max ", comment: "") + String(format: "%.0f ", informations.stats.vitesseMaxSession * informations.facteurUniteVitesse) + informations.texteUniteVitesse)
//                    .font(Font.monospacedDigit(Font.callout)())
//                    Text(String(format: "%.1f " + informations.texteUniteDistance, informations.stats.distanceTotaleSession * informations.facteurUniteDistance))
//                    .font(Font.monospacedDigit(Font.callout)())
//                let messageDenivele = texteAffichageValeur(prefixe: "➚ ", format: "%4.0f", valeur: informations.stats.denivelePositifSession * informations.facteurUniteAltitude, unite: informations.texteUniteAltitude) + " " + texteAffichageValeur(prefixe: "➘ ", format: "%4.0f", valeur: informations.stats.deniveleNegatifSession * informations.facteurUniteAltitude, unite: informations.texteUniteAltitude)
//                Text(messageDenivele)
//                    .font(Font.monospacedDigit(Font.callout)())
//            } // VStack
//            .tabItem{
//                Label("Stats", systemImage: "list.number")
//            }

            
//        } // TabView
    } // body
    
//    func texteAffichageValeur(prefixe: String, format: String, valeur: Double, unite: String) -> String {
//        return prefixe + String(format: format, valeur).replacingOccurrences(of: " ", with: "\u{2007}") + " " + unite  // .replacingOccurrences(of: " ", with: "\u{2007}")
//    }
    
}

#Preview {
    ContentView()
}

//extension View {
//    func hiddenConditionally(isHidden: Bool) -> some View {
//        isHidden ? AnyView(self.hidden()) : AnyView(self)
//    }
//}

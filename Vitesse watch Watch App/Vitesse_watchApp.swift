//
//  Vitesse_watchApp.swift
//  Vitesse watch Watch App
//
//  Created by Jérôme Kasparian on 23/06/2026.
//

import SwiftUI

@main
struct Vitesse_watch_Watch_AppApp: App {
    @StateObject var informationVitesse = InformationsVitesse()
    init() {
        print("démarrage")
    }
        
    
    var body: some Scene {
        WindowGroup {
            TabView {
                ContentView()
                    .environmentObject(informationVitesse)
                    .tabItem{
                        Label("Vitesse", systemImage: "numbers")
                    }
                StatsViewWatch()
                    .environmentObject(informationVitesse)
                    .tabItem{
                        Label("Stats", systemImage: "list.number")
                    }
            }
        }

    }
    
    
}


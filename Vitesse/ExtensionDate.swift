//
//  ExtensionDate.swift
//  RechercheRadiosonde
//
//  Created by Jérôme Kasparian on 10/06/2024.
//

import Foundation

extension Date{
    func GMTenTexte() -> String {
        let dateLocale = self + Double(Calendar.current.timeZone.secondsFromGMT())
        // + Calendar.current.timeZone.daylightSavingTimeOffset(for: Date()) // VERIFIER AVEC L'HORAORE D'HIVER
        return String(dateLocale.description.prefix(19).suffix(8))
    }
    
}

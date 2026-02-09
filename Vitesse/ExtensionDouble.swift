//
//  ExtensionDouble.swift
//  RechercheRadiosonde
//
//  Created by Jérôme Kasparian on 25/07/2023.
//

import Foundation

extension Double {
    func modulo360CentreSurZero() -> Double {
        var angle2 = self
        while angle2 > 180 {angle2 = angle2 - 360}
        while angle2 <= -180 {angle2 = angle2 + 360}
        return angle2
    }
    
    func modulo360() -> Double {
        var angle2 = self
        while angle2 >= 360 {angle2 = angle2 - 360}
        while angle2 < 0 {angle2 = angle2 + 360}
        return angle2
    }

    func arrondi10() -> Double {
        let divisePar10: Double = self / 10.0
        let valeurArrondie = roundl(divisePar10) * 10.0
        return valeurArrondie
    }



}

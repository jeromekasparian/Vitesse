//
//  ExtensionString.swift
//  Vitesse
//
//  Created by Jérôme Kasparian on 09/01/2026.
//

import UIKit
extension String {
    var floatValue: Float {
        return (self as NSString).floatValue
    }
}

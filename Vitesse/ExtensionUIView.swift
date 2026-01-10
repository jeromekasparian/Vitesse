//
//  ExtensionUIView.swift
//  Vitesse
//
//  Created by Jérôme Kasparian on 09/01/2026.
//

import UIKit

extension UIView {
    
    /// Flip view horizontally.
    func flipX() {
        transform = CGAffineTransform(scaleX: -transform.a, y: transform.d)
    }
    
    /// Flip view vertically.
    func flipY() {
        transform = CGAffineTransform(scaleX: transform.a, y: -transform.d)
    }
    
}

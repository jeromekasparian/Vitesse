//
//  ExtensionUIViewController.swift
//  Vitesse
//
//  Created by Jérôme Kasparian on 09/01/2026.
//

import UIKit

extension ViewController {
    func afficherAlerteRenvoiPreferences(titre: String, message: String, perfsDeLApp: Bool, optionNePlusMontrer: Bool) {
        DispatchQueue.main.async {
            //        let changePrivacySetting = "AVCam doesn't have permission to use the camera, please change privacy settings"
            //        let message = NSLocalizedString(changePrivacySetting, comment: "Alert message when the user has denied access to the camera")
            //            let titre = NSLocalizedString("Autorisez la localisation", comment: "Titre de l'alerte")
            let alertController = UIAlertController(title: titre, message: message, preferredStyle: .alert)
            if optionNePlusMontrer {
                alertController.addAction(UIAlertAction(title: NSLocalizedString("Ne plus afficher", comment: ""), style: .default, handler: {_ in self.userDefaults.set(true, forKey: keyAlerteLocationToujoursDejaAffichee)}))
            }
            alertController.addAction(UIAlertAction(title: NSLocalizedString("Annuler", comment: "Alert Cancel button"), style: .cancel, handler: nil))
            var urlAOuvrir: URL?
            if perfsDeLApp {
                urlAOuvrir = URL(string: UIApplication.openSettingsURLString)  // url pour ouvrir les préférences de l'app appelante
            } else {
                urlAOuvrir = URL(string:"App-Prefs::root=Settings&path=General")  // url pour ouvrir les l'app Préférences : à la racine sauf si elle est déjà ouverte sur une sous-page. A noter que c'est manifestement une url pas 100% publique de la part d'Apple, donc susceptible de dysfonctionner à l'avenir.
            }
            if urlAOuvrir != nil {
                alertController.addAction(UIAlertAction(title: NSLocalizedString("Settings", comment: "Alert button to open Settings"), style: .`default`, handler: { _ in
                    UIApplication.shared.open(urlAOuvrir!, options: [:], completionHandler: nil)
                }))
            }
            DispatchQueue.main.async {
                self.present(alertController, animated: true, completion: nil)
            }
        }
    }
    
}

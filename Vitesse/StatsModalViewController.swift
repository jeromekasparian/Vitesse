//
//  StatsModalViewController.swift
//  Vitesse
//
//  Created by Jérôme Kasparian on 01/05/2021.
//

import UIKit

class StatsModalViewController: UIViewController {
    
    @IBOutlet var labelVitesseMax: UILabel!
    @IBOutlet var labelVitesseMaxSession: UILabel!
    @IBOutlet var labelDistanceTotale: UILabel!
    @IBOutlet var labelDistanceTotaleSession: UILabel!
    @IBOutlet var boutonEffacerSession: UIButton!
    @IBOutlet var boutonEffacerTotal: UIButton!
//    @IBOutlet var affichageTempsSession: UILabel!
    @IBOutlet var switchAffichageTeteHaute: UISwitch!
    @IBOutlet var labelAffichageTeteHaute: UILabel!
    @IBOutlet var boutonOK: UIButton!
    @IBOutlet var imageChevron: UIImageView!
    @IBOutlet var labelVitesseMoyenne: UILabel!
    @IBOutlet var labelDeniveleSession: UILabel!
    @IBOutlet var labelTitreTrajetEnCours: UILabel!
    @IBOutlet var labelPasLocalisationToujours: UILabel!
    
    var alerteLocationToujoursDejaAffichee: Bool = false
    let keyAlerteLocationToujoursDejaAffichee = "keyAlerteLocationToujoursDejaAffichee"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        alerteLocationToujoursDejaAffichee = userDefaults.value(forKey: keyAlerteLocationToujoursDejaAffichee) as? Bool ?? false
        statsEstOuvert = true
        stoppeLuminositeMax()
        switchAffichageTeteHaute.isOn = autoriserAffichageTeteHaute
        boutonEffacerSession.setTitle("", for: .normal)
        if #available(iOS 13.0, *) {
            boutonEffacerSession.setImage(UIImage(systemName: "delete.left", withConfiguration: UIImage.SymbolConfiguration(pointSize: 23)), for: .normal)
//            boutonEffacerSession.tintColor = .label
            boutonEffacerTotal.setImage(UIImage(systemName: "delete.left", withConfiguration: UIImage.SymbolConfiguration(pointSize: 23)), for: .normal)
//            boutonEffacerTotal.tintColor = .label
        } else {
            // Fallback on earlier versions
            boutonEffacerSession.setImage(UIImage(named: "delete.left"), for: .normal)
//            boutonEffacerSession.tintColor = .black
            boutonEffacerTotal.setImage(UIImage(named: "delete.left"), for: .normal)
//            boutonEffacerTotal.tintColor = .black
            boutonOK.isHidden = false
            imageChevron.isHidden = true
        }
        boutonEffacerTotal.setTitle("", for: .normal)
        //        boutonEffacerSession.setImage(UIImage(systemName: "xmark"), for: .normal)
        afficherStats()
        NotificationCenter.default.addObserver(self, selector: #selector(afficherStats), name: NSNotification.Name(rawValue: notificationMiseAJourStats), object: nil)
        // Do any additional setup after loading the view.
        
        // mise en place de la détection du swipe down pour fermer le tiroir des stats
        let swipeBas = UISwipeGestureRecognizer(target:self, action: #selector(fermerStats))
        swipeBas.direction = UISwipeGestureRecognizer.Direction.down
        self.view.addGestureRecognizer(swipeBas)
        labelVitesseMax.font = UIFont.monospacedDigitSystemFont(ofSize: labelVitesseMax.font.pointSize, weight: .regular)
        labelDistanceTotale.font = UIFont.monospacedDigitSystemFont(ofSize: labelDistanceTotale.font.pointSize, weight: .regular)
        labelVitesseMaxSession.font = UIFont.monospacedDigitSystemFont(ofSize: labelVitesseMaxSession.font.pointSize, weight: .regular)
        labelDistanceTotaleSession.font = UIFont.monospacedDigitSystemFont(ofSize: labelDistanceTotaleSession.font.pointSize, weight: .regular)
        labelVitesseMoyenne.font = UIFont.monospacedDigitSystemFont(ofSize: labelVitesseMoyenne.font.pointSize, weight: .regular)
        labelDeniveleSession.font = UIFont.monospacedDigitSystemFont(ofSize: labelDeniveleSession.font.pointSize, weight: .regular)
//        affichageTempsSession.font = UIFont.monospacedDigitSystemFont(ofSize: affichageTempsSession.font.pointSize, weight: .regular)
//        affichageTempsSession.text = ""
        labelPasLocalisationToujours.text = locationToujoursAutorisee ? "" : NSLocalizedString("L'app n'a pas accès à la localisation lorsqu'elle est en arrière-plan, les statistiques seront peu précises", comment: "")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if !locationToujoursAutorisee && !alerteLocationToujoursDejaAffichee {
            afficherAlerteRenvoiPreferences(titre: NSLocalizedString("Autorisez la localisation en arrière-plan", comment: "Titre de l'alerte"), message: NSLocalizedString("La localisation n'est pas autorisée lorsque l'app est en arrière-plan. Les statistiques risquent d'être fausses. Vous pouvez autoriser la localisation en arrière plan dans les préférences de l'app.", comment: ""), perfsDeLApp: true)
            alerteLocationToujoursDejaAffichee = true
            userDefaults.set(true, forKey: keyAlerteLocationToujoursDejaAffichee)
        }
        DispatchQueue.main.async {
            self.labelPasLocalisationToujours.isHidden = locationToujoursAutorisee
        }
    }
    @IBAction func changeAutorisationTeteHaute(){
        autoriserAffichageTeteHaute = switchAffichageTeteHaute.isOn
        userDefaults.set(autoriserAffichageTeteHaute, forKey: keyAutoriserAffichageTeteHaute)
    }
    
    @IBAction func fermerStats () {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func effacerSession() {
        vitesseMaxSession = 0.0
        distanceTotaleSession = 0.0
        denivelePositifSession = 0.0
        deniveleNegatifSession = 0.0
//        premierTempsValide = 0.0 // Date(timeIntervalSinceNow: 0.0).timeIntervalSince1970
        tempsSession = 0.0
//        timeStampDernierePosition = 0.0
        afficherStats()
    }
    
    
    @IBAction func effacerTout() {
        let alert = UIAlertController(title: NSLocalizedString("Effacer les statistiques ?", comment: "Titre alerte"), message: NSLocalizedString("Êtes-vous sûr de vouloir effacer définitivement toutes les statistiques ?", comment: "Contenu de l'alerte"), preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("Annuler", comment: "bouton Annuler"), style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: NSLocalizedString("Effacer", comment: "bouton OK"), style: .destructive, handler: {_ in self.effacerToutVraiment()}))
        DispatchQueue.main.async {
            self.present(alert, animated: true)
        }
    }
    
    @objc func effacerToutVraiment() {
        vitesseMaxSession = 0.0
        distanceTotaleSession = 0.0
        denivelePositifSession = 0.0
        deniveleNegatifSession = 0.0
        vitesseMax = 0.0
        distanceTotale = 0.0
//        premierTempsValide = 0.0 // Date(timeIntervalSinceNow: 0.0).timeIntervalSince1970
        tempsSession = 0.0
        afficherStats()
    }
    
    @objc func afficherStats(){
        DispatchQueue.main.async {
            if demoMode {
                self.labelVitesseMax.text = "112 km/h"
                self.labelVitesseMaxSession.text = "83 km/h"
                self.labelDistanceTotale.text = "1848.5 km"
                self.labelDistanceTotaleSession.text = "24.0 km"
                self.labelDeniveleSession.text = "➚ 425 m, ➘ 193 m"
                self.labelVitesseMoyenne.text = NSLocalizedString("Moyenne ", comment: "") + "37 km/h"
            }
            else {
                self.labelVitesseMax.text = (vitesseMax >= 100.0 ? String(format: "Max %3.0f ", vitesseMax * facteurUnites[unite]) + textesUnites[unite] : String(format: "Max %4.1f ", vitesseMax * facteurUnites[unite]) + textesUnites[unite]).replacingOccurrences(of: " ", with: "\u{2007}")
                self.labelVitesseMaxSession.text = (vitesseMaxSession >= 100.0 ? String(format: "Max %3.0f ", vitesseMaxSession * facteurUnites[unite]) + textesUnites[unite] : String(format: "Max %4.1f ", vitesseMaxSession * facteurUnites[unite]) + textesUnites[unite]).replacingOccurrences(of: " ", with: "\u{2007}")
                if (unite == 0) { self.labelDistanceTotale.text = String(format: "%4.0f ", distanceTotale * facteurUnitesDistance[unite]).replacingOccurrences(of: " ", with: "\u{2007}") }
                else { self.labelDistanceTotale.text = String(format: "%.1f ", distanceTotale * facteurUnitesDistance[unite]).replacingOccurrences(of: " ", with: "\u{2007}") }
                self.labelDistanceTotale.text?.append(textesUnitesDistance[unite])
                if (unite == 0) { self.labelDistanceTotaleSession.text = String(format: "%.0f ", distanceTotaleSession * facteurUnitesDistance[unite]).replacingOccurrences(of: " ", with: "\u{2007}").replacingOccurrences(of: " ", with: "\u{2007}") }
                else { self.labelDistanceTotaleSession.text = String(format: "%.1f ", distanceTotaleSession * facteurUnitesDistance[unite]).replacingOccurrences(of: " ", with: "\u{2007}") }
                self.labelDistanceTotaleSession.text?.append(textesUnitesDistance[unite])
                if self.view.frame.width > self.view.frame.height {
                    self.labelDeniveleSession.text = (String(format: "➚ %4.0f", denivelePositifSession  * facteurUnitesAltitude[unite]) + textesUnitesAltitude[unite] + String(format: ", ➘ %4.0f", deniveleNegatifSession * facteurUnitesAltitude[unite]) + textesUnitesAltitude[unite]).replacingOccurrences(of: " ", with: "\u{2007}").replacingOccurrences(of: ",", with: ", ") //.replacingOccurrences(of: "➚", with: "➚ ").replacingOccurrences(of: "➘", with: "➘ ")
                } else {
                    self.labelDeniveleSession.text = (String(format: "➚ %4.0f", denivelePositifSession  * facteurUnitesAltitude[unite]) + textesUnitesAltitude[unite] + "\n➘ " + String(format: "%4.0f", deniveleNegatifSession * facteurUnitesAltitude[unite]) + textesUnitesAltitude[unite]).replacingOccurrences(of: " ", with: "\u{2007}")
                }
                //            if (premierTempsValide == 0.0) || !debugMode {
                //                affichageTempsSession.isHidden = true
                //            }
                //            else {
                //                let tempsSession = abs(Int(Date(timeIntervalSince1970: premierTempsValide).timeIntervalSinceNow))
                let secondes = Int(tempsSession) % 60
                let minutesTot = Int(tempsSession) / 60
                let minutes = minutesTot % 60
                let heures = minutesTot / 60
                var message = heures > 0 ? String(format:NSLocalizedString("Trajet (%d h %02d min", comment: ""), heures, minutes) : String(format:NSLocalizedString("Trajet (%02d min", comment: ""), minutes)
                if debugMode {
                    message = message.appending(String(format:" %02d s", secondes))
                    //                    if tempsSession < 0 {
                    //                        affichageTempsSession.textColor = .red
                    //                    }
                }
                message = message + ")"
                self.labelTitreTrajetEnCours.text = message
                //            affichageTempsSession.text = message
                //                affichageTempsSession.isHidden = false
                let vitesseMoyenne = distanceTotaleSession / tempsSession
                if vitesseMoyenne.isFinite && tempsSession >= 10.0 && vitesseMoyenne < vitesseMaxSession {
                    self.labelVitesseMoyenne.text = (vitesseMoyenne < 100.0 ? NSLocalizedString("Moyenne ", comment: "") + String(format: "%4.1f ", vitesseMoyenne * facteurUnites[unite]) + textesUnites[unite] :
                                                    NSLocalizedString("Moyenne ", comment: "") + String(format: "%3.0f ", vitesseMoyenne * facteurUnites[unite]) + textesUnites[unite]).replacingOccurrences(of: " ", with: "\u{2007}")
                } else {
                    self.labelVitesseMoyenne.text = NSLocalizedString("Moyenne ", comment: "") + " ---  " + textesUnites[unite]
                }
                //            }
            }
        }
    }
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destination.
     // Pass the selected object to the new view controller.
     }
     */
    
    
    override func viewWillDisappear(_ animated: Bool) {
        statsEstOuvert = false
        super.viewWillDisappear(true)
    }
    
    override func viewDidLayoutSubviews() {
        afficherStats()
    }
}

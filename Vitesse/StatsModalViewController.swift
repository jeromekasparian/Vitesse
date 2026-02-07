//
//  StatsModalViewController.swift
//  Vitesse
//
//  Created by Jérôme Kasparian on 01/05/2021.
//

import UIKit

protocol StatsModalDelegate: AnyObject {
    func statsModalViewControllerDidTapEffacerSession(_ viewController: StatsModalViewController)
    func statsModalViewControllerDidTapEffacerTotal(_ viewController: StatsModalViewController)
    func afficherStatsReelles(_ viewController: StatsModalViewController)
    func actualiserAffichageTeteHaute(autoriserAffichageTeteHaute: Bool)
    func changeUnite()
//    func statsModalViewControllerDidTapOK(_ viewController: StatsModalViewController)
}

class StatsModalViewController: UIViewController {
    
    @IBOutlet var labelVitesseMax: UILabel!
    @IBOutlet var labelVitesseMaxSession: UILabel!
    @IBOutlet var labelDistanceTotale: UILabel!
    @IBOutlet var labelDistanceTotaleSession: UILabel!
    @IBOutlet var boutonEffacerSession: UIButton!
    @IBOutlet var boutonEffacerTotal: UIButton!
    @IBOutlet var switchAffichageTeteHaute: UISwitch!
    @IBOutlet var labelAffichageTeteHaute: UILabel!
    @IBOutlet var boutonOK: UIButton!
    @IBOutlet var imageChevron: UIImageView!
    @IBOutlet var labelVitesseMoyenne: UILabel!
    @IBOutlet var labelDeniveleSession: UILabel!
    @IBOutlet var labelTitreTrajetEnCours: UILabel!
    @IBOutlet var labelPasLocalisationToujours: UILabel!
    @IBOutlet var boutonUnite: UIButton!

//    var stats = Stats()
    var autoriserAffichageTeteHaute = true
    var userDefaults = UserDefaults.standard
    var locationToujoursAutorisee: Bool = false
    var demoMode = false // pour faire les captures d'écran pour l'app store

    var alerteLocationToujoursDejaAffichee: Bool = false
    let keyAlerteLocationToujoursDejaAffichee = "keyAlerteLocationToujoursDejaAffichee"
    var delegate: StatsModalDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        alerteLocationToujoursDejaAffichee = userDefaults.value(forKey: keyAlerteLocationToujoursDejaAffichee) as? Bool ?? false
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
//        NotificationCenter.default.addObserver(self, selector: #selector(afficherStats), name: NSNotification.Name(rawValue: notificationMiseAJourStats), object: nil)
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
            self.labelPasLocalisationToujours.isHidden = self.locationToujoursAutorisee
        }
    }
    @IBAction func changeAutorisationTeteHaute(){
        autoriserAffichageTeteHaute = switchAffichageTeteHaute.isOn
        self.delegate?.actualiserAffichageTeteHaute(autoriserAffichageTeteHaute: switchAffichageTeteHaute.isOn)
        userDefaults.set(autoriserAffichageTeteHaute, forKey: keyAutoriserAffichageTeteHaute)
    }
    
    @IBAction func fermerStats () {
//        statsModalViewControllerDidTapOK(self)
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func effacerSession() {
        delegate?.statsModalViewControllerDidTapEffacerSession(self)
//        vitesseMaxSession = 0.0
//        distanceTotaleSession = 0.0
//        denivelePositifSession = 0.0
//        deniveleNegatifSession = 0.0
//        tempsSession = 0.0
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
        delegate?.statsModalViewControllerDidTapEffacerTotal(self)
//        vitesseMaxSession = 0.0
//        distanceTotaleSession = 0.0
//        denivelePositifSession = 0.0
//        deniveleNegatifSession = 0.0
//        vitesseMax = 0.0
//        distanceTotale = 0.0
////        premierTempsValide = 0.0 // Date(timeIntervalSinceNow: 0.0).timeIntervalSince1970
//        tempsSession = 0.0
        afficherStats()
    }
    
    @objc func afficherStats(){
        DispatchQueue.main.async {
            if self.demoMode {
                self.labelVitesseMax.text = "112 km/h"
                self.labelVitesseMaxSession.text = "83 km/h"
                self.labelDistanceTotale.text = "1848.5 km"
                self.labelDistanceTotaleSession.text = "24.0 km"
                self.labelDeniveleSession.text = "➚ 425 m, ➘ 193 m"
                self.labelVitesseMoyenne.text = NSLocalizedString("Moyenne ", comment: "") + "37 km/h"
            }
            else {
                self.delegate?.afficherStatsReelles(self)
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
        super.viewWillDisappear(true)
    }
    
    override func viewDidLayoutSubviews() {
        afficherStats()
    }
    
    @IBAction func boutonUniteAppuye() {
        delegate?.changeUnite()
        afficherStats()
    }
}

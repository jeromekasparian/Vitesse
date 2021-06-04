//
//  ViewController.swift
//  Vitesse
//
//  Created by Jérôme Kasparian on 25/04/2021.
//

/// feuille de route
//  incohérences sur la vitesse max / distance totale au démarrage
// la statusbar ne se cache pas sous ios 14.5 ??
// Localisation DE
// mettre un faux bouton refresh?
// Chrono basé sur les modes de transport
// icone en niveaux de gris


import UIKit
import CoreLocation
import CoreMotion
//import SystemConfiguration
//import CallKit

let autoriseDebug = true
var debugMode: Bool = false
let demoMode = false // pour faire les captures d'écran pour l'app store

let keyUnite = "uniteAuDemarrage"
let keyVitesseMax = "vitesseMax"
let keyDistanceTotale = "distanceTotale"
let notificationMiseAJourStats = "miseAJourStats"
var vitesseMax = 0.0
var vitesseMaxSession = 0.0
var distanceTotale = 0.0
var distanceTotaleSession = 0.0
var tempsSession = 0.0  // le temps total de trajet, en secondes

//var premierTempsValide = 0.0
var unite: Int = 1 // par défaut, km/h
let textesUnites: [String] = [NSLocalizedString("m/s", comment: "vistesse : m/s"),NSLocalizedString("km/h", comment: "vitesse : km/h"),NSLocalizedString("mph", comment: "vitesse : mph")]
let facteurUnites: [Double] = [1.0, 3.6, 2.2369362920544]
let textesUnitesDistance: [String] = [NSLocalizedString("m", comment: "distance : m"),NSLocalizedString("km", comment: "distance : km"),NSLocalizedString("mi", comment: "distance : mi")]
let facteurUnitesDistance: [Double] = [1.0, 0.001, 0.00062137]
var nombrePositionsLues = 0
var timeStampDernierePosition = 0.0
var luminositeEcranSysteme = CGFloat(0.0)
var luminositeEstForcee = false
let autoriseAffichageTeteHauteBlanc = false
let tempsMaxEntrePositions = 5.0 // temps en secondes au-delà duquel on considère qu'on a perdu la position
let nbPositionsMiniAuDemarrage = 5 // nombre de positions qu'on lit avant de les prendre en compte.
var statsEstOuvert = false
let tempsAvantReinitialisationAuto = Double(3600 * 12) // temps en secondes au-delà duquel on réinitialise les stats de trajet
var localisationEstPerdue = false
let distanceMiniAvantComptageTemps = 30.0  // on considère qu'on est en marche si on a parcouru au moins 30 m
let userDefaults = UserDefaults.standard

class ViewController: UIViewController, CLLocationManagerDelegate {
    
    var locationManager: CLLocationManager! = CLLocationManager()
    let inclinaisonMin = 5.0 // inclinaison min en degres (sur le roulis) pour dire qu'on est en mode tête haute
    let inclinaisonMax = 38.0 // inclinaison max en degres (sur le roulis) pour dire qu'on est en mode tête haute
    let radiansEnDegres = 180.0 / 3.14
    var positionTeteHaute: Bool = false
    var anciennePositionTeteHaute: Bool = false
    var locationPrecedente: CLLocation! = nil
    var affichageTeteHauteBlanc = false
    var timer = Timer()
    var nombrePasOK = 0 // nombre de vitesses pas ok reçues à la suite
    
    let motionManager = CMMotionManager()
    
    @IBOutlet weak var affichageVitesse: UILabel!
    @IBOutlet weak var gabaritAffichageVitesse: UILabel!
    @IBOutlet var affichageUnite: UIButton!
    @IBOutlet var imagePasLocalisation: UIImageView!
    @IBOutlet var roueAttente: UIActivityIndicatorView!
    @IBOutlet var messagePublic: UILabel!  
    @IBOutlet var messageDebug: UILabel!  // caché dans l'interface - utile pour les tests de début
    @IBOutlet var boutonOuvreStats: UIButton!
    
    @IBAction func changeUnite () {
        unite = (unite + 1) % 3
        userDefaults.set(unite, forKey: keyUnite)
        affichageUnite.setTitle(textesUnites[unite], for: .normal) // = textesUnites[unite]
        if (affichageVitesse.text != "") {
            let laVitesse = Double(affichageVitesse.text?.floatValue ?? -1.0)
            afficherVitesse(vitesse: laVitesse, precisionOK: true)
        }
    }
    
    @objc func ouvreStats() {
        //        print("perform segue")
        performSegue(withIdentifier:"OuvreStats", sender: self)
    }
    
    @objc func changeDebugMode() {
        debugMode = !debugMode
        DispatchQueue.main.async{
            self.messageDebug.isHidden = !debugMode
        }
    }
    
    @objc func changeCouleurTeteHaute() {
        if autoriseAffichageTeteHauteBlanc{
            affichageTeteHauteBlanc = !affichageTeteHauteBlanc
        }
    }
    
    override func viewDidLoad() {
        //        justLoaded = true
        debugMode = debugMode && autoriseDebug
        
        // mise en place de la détection du swipe up pour ouvrir le tiroir des stats
        let swipeHaut = UISwipeGestureRecognizer(target:self, action: #selector(ouvreStats))
        swipeHaut.direction = UISwipeGestureRecognizer.Direction.up
        self.view.addGestureRecognizer(swipeHaut)
        
        // mise en place de la détection du swipe left à 3 doigts pour activer le mode debug
        let swipeDebug = UISwipeGestureRecognizer(target:self, action: #selector(changeDebugMode))
        swipeDebug.direction = UISwipeGestureRecognizer.Direction.left
        swipeDebug.numberOfTouchesRequired = 3
        self.view.addGestureRecognizer(swipeDebug)
        
        if autoriseAffichageTeteHauteBlanc{
            // mise en place de la détection du swipe right à 3 doigts pour activer le mode tête haute blanc
            let swipeBlanc = UISwipeGestureRecognizer(target:self, action: #selector(self.changeCouleurTeteHaute))
            swipeBlanc.direction = UISwipeGestureRecognizer.Direction.right
            swipeBlanc.numberOfTouchesRequired = 3
            self.view.addGestureRecognizer(swipeBlanc)
        }
        
        
        //        locationManager.requestWhenInUseAuthorization()
        gereDroitsLocalisation(origineViewDidLoad: true, origineViewDidAppear: false)
        
        motionManager.deviceMotionUpdateInterval = 1
        // Get attitude orientation
        motionManager.startDeviceMotionUpdates(to: .main, withHandler: gereOrientation) //{ (motion, error) in
        
        NotificationCenter.default.addObserver(self, selector: #selector(gereDroitsLocationDepuisNotification), name: UIApplication.didBecomeActiveNotification, object: nil)
        
        UIApplication.shared.isIdleTimerDisabled = true
        
        // tester si on a une connexion
        
        //        let envoyerAlerteSecurite = !nePasDerangerActif() || connectedToNetwork()
        //        if connectedToNetwork(){}
        
        boutonOuvreStats.setTitle("", for: .normal)
        boutonOuvreStats.setImage(UIImage(systemName: "chevron.compact.up", withConfiguration: UIImage.SymbolConfiguration(pointSize: 48)), for: .normal)
        let alert = UIAlertController(title: NSLocalizedString("Pour votre sécurité", comment: "Titre alerte"), message: NSLocalizedString("avant de conduire, assurez-vous que le mode Avion ou \"Ne pas déranger en voiture\" est activé", comment: "Contenu de l'alerte de sécurité"), preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "bouton OK"), style: .default, handler: {_ in print("Alerte NPD validée")}))
        DispatchQueue.main.async{
            self.messagePublic.text = ""
            self.messageDebug.isHidden = !debugMode
            self.affichageVitesse.text = ""
            self.adapterTailleAffichageVitesse()
            unite = userDefaults.value(forKey: keyUnite) as? Int ?? 1
            vitesseMax = userDefaults.value(forKey: keyVitesseMax) as? Double ?? 0.0
            distanceTotale = userDefaults.value(forKey: keyDistanceTotale) as? Double ?? 0.0
            
            self.affichageUnite.setTitle(textesUnites[unite], for: .normal)
            self.present(alert, animated: true)
            
//            self.gabaritAffichageVitesse.isHidden = false
//            self.gabaritAffichageVitesse.text = String(format:"\u{2007}%d",5)
        }
        scheduledTimerWithTimeInterval()
        super.viewDidLoad()
        print("init ok")
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        DispatchQueue.main.async{
            self.adapterTailleAffichageVitesse()
        }
    }
    
    func adapterTailleAffichageVitesse(){
        let laTailleDePoliceAvecLaBonneHauteur = self.gabaritAffichageVitesse.font.pointSize * self.gabaritAffichageVitesse.bounds.size.height / self.gabaritAffichageVitesse.font.capHeight * 0.95
        //            print(laTailleDePoliceAvecLaBonneHauteur, self.affichageVitesse.font.pointSize, self.affichageVitesse.bounds.size.height, self.affichageVitesse.font.lineHeight)
        self.affichageVitesse.font = UIFont.monospacedDigitSystemFont(ofSize: laTailleDePoliceAvecLaBonneHauteur, weight: .regular)
        self.gabaritAffichageVitesse.font = UIFont.monospacedDigitSystemFont(ofSize: laTailleDePoliceAvecLaBonneHauteur, weight: .regular)
//        self.affichageVitesse.font = UIFont.monospacedSystemFont(ofSize: laTailleDePoliceAvecLaBonneHauteur, weight: .regular)
        print(self.affichageVitesse.font.capHeight)
    }
    
    func scheduledTimerWithTimeInterval(){
        // Scheduling timer to Call the function "updateCounting" with the interval of 1 seconds
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.verifieQueLocalisationEstActive), userInfo: nil, repeats: true)
    }
    
    @objc func verifieQueLocalisationEstActive() {
        if (self.imagePasLocalisation.isHidden && ((Date().timeIntervalSince1970 -  timeStampDernierePosition) > tempsMaxEntrePositions)) {
            localisationEstPerdue = true
            DispatchQueue.main.async{
                if demoMode{
                    self.afficherVitesse(vitesse: 1, precisionOK: true)
                }
                else {
                    //                    self.messageSecret.isHidden = false
                    var leMessage =  NSLocalizedString("Localisation perdue", comment:"Localisation perdue")
                    if #available(iOS 14.0, *) {
                        if self.locationManager.accuracyAuthorization == .reducedAccuracy{
                            leMessage = NSLocalizedString("Précision réduite", comment:"Basse précision autorisée")
                        }
                    }
                    self.messagePublic.text = leMessage
                    self.affichageVitesse.text = ""
                    self.imagePasLocalisation.isHidden = false
                }
                self.roueAttente.stopAnimating()
            }
        }
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        enregistrerStats()
        if luminositeEstForcee { UIScreen.main.brightness = luminositeEcranSysteme }
        luminositeEstForcee = false
        timer.invalidate()
        super.viewWillDisappear(true)
    }
    //    override func viewDidAppear(_ animated: Bool) {
    //        if !justLoaded {
    //            gereDroitsLocalisation(origineViewDidLoad: false, origineViewDidAppear: true)
    //        }
    //        justLoaded = false
    //    }
    
    func gereOrientation(motion:CMDeviceMotion?,error:Error?) {
        let tangage = motion!.attitude.pitch * radiansEnDegres  // basculement vers l'avant
        let roulis = motion!.attitude.roll * radiansEnDegres    // basculement vers le côté
        //        let azimutInverse = motion!.attitude.yaw * radiansEnDegres    // Azimut, haut du téléphone vers le sud = 0
        //        print(String(format:"orientation : %.2f, %.2f, %.2f", tangage, roulis, azimutInverse))
        //            nouveauDresse = (abs(roulis) > inclinaisonMax)
        //        nouveauDresse = (!(UIDevice.current.orientation.isLandscape) || (abs(roulis) > inclinaisonMax))
        //        nouveauDresse = ((abs(roulis) < abs(tangage) + inclinaisonMin) || (abs(roulis) > inclinaisonMax) || (abs(roulis) < inclinaisonMin))
        positionTeteHaute = (abs(roulis) < inclinaisonMax) && (abs(roulis) > inclinaisonMin) && (abs(roulis) > abs(tangage) + inclinaisonMin) && (UIApplication.shared.windows.first?.windowScene?.interfaceOrientation.isLandscape ?? false) // UIDevice.current.orientation.isLandscape est l'orientation physique de l'appareil, quand on est plus ou moins à plat il dit "à plat"
        DispatchQueue.main.async{
            if (self.positionTeteHaute != self.anciennePositionTeteHaute) {
                self.affichageVitesse.flipX()
                self.affichageUnite.flipX()
                self.anciennePositionTeteHaute = self.positionTeteHaute
            } // position a changé
            if self.positionTeteHaute {  // le téléphone est à plat -> on affiche le texte en blanc pour réflexion sur le pare-brise
                if self.affichageTeteHauteBlanc {
                    self.affichageVitesse.textColor = .black
                    self.affichageVitesse.backgroundColor = .white
                }
                else {
                    self.affichageVitesse.textColor = .white
                }
                // on force l'écran à rester en mode portrait
                if !luminositeEstForcee && !statsEstOuvert { //isUserInteractionEnabled { // && self.view.isFirstResponder)
                    luminositeEcranSysteme = UIScreen.main.brightness   // on note la luminosité de l'écran, pour pouvoir y revenir plus tard
                    UIScreen.main.brightness = CGFloat(1.0)  // on met le contraste au max
                    luminositeEstForcee = true
                }
                //                AppDelegate.orientationLock = UIInterfaceOrientationMask.landscape
                //                if roulis > 0 { UIDevice.current.setValue(UIInterfaceOrientation.landscapeLeft.rawValue, forKey: "orientation") }
                //                else { UIDevice.current.setValue(UIInterfaceOrientation.landscapeRight.rawValue, forKey: "orientation") }
                //                UIViewController.attemptRotationToDeviceOrientation()
                
                //                print("à plat")
            }  // téléphone à plat -> position tête haute
            else { // le téléphone est penché -> on affiche le texte en gris pour lecture directe
                self.affichageVitesse.textColor = .lightGray
                if self.affichageTeteHauteBlanc {
                    self.affichageVitesse.backgroundColor = .black
                }
                if luminositeEstForcee { // on revient au contraste par défaut du système
                    UIScreen.main.brightness = luminositeEcranSysteme
                    luminositeEstForcee = false
                }
                //                AppDelegate.orientationLock = UIInterfaceOrientationMask.all  // on déverrouille l'orientation de l'écran
                //                print("dressé")
            }  // téléphone dressé
            //            self.affichageUnite.setTitle(textesUnites[unite], for: .normal) // = textesUnites[unite]
        } // DispatchQueue.main.async
    }
    
    @objc func gereDroitsLocationDepuisNotification() {
        //        locationManager.requestWhenInUseAuthorization()
        gereDroitsLocalisation(origineViewDidLoad : false, origineViewDidAppear: false)
    }
    
    func gereDroitsLocalisation(origineViewDidLoad : Bool, origineViewDidAppear: Bool) {
        print("lancement viewDidLoad : \(origineViewDidLoad)")
        print("lancement viewDidAppear : \(origineViewDidAppear)")
        
        locationManager.delegate = self
        
        if (CLLocationManager.locationServicesEnabled()) { // la localisation est activée sur l'appareil
            print("droits de localisation : ", CLLocationManager.authorizationStatus().rawValue)
            locationManager.requestWhenInUseAuthorization()
            
            switch CLLocationManager.authorizationStatus() {
            case .authorizedAlways, .authorizedWhenInUse:  // l'app a l'autorisation d'accéder à la localisation
                locationManager.desiredAccuracy = kCLLocationAccuracyBest
                locationManager.startUpdatingLocation();
                print("acces localisation ok")
                //            self.imagePasDeVitesse.image = UIImage(systemName: "location.fill")
                DispatchQueue.main.async{
                    self.messageDebug.text = "Localisation autorisée"
                    //                    self.messageSecret.isHidden = !debugMode
                    if self.imagePasLocalisation.isHidden {
                        self.affichageVitesse.text = ""
                        //                    self.imagePasLocalisation.isHidden = true
                        self.roueAttente.startAnimating()  //isHidden = true
                    }
                }
            case .denied, .restricted:
                print("acces localisation pas ok pour l'app")
                DispatchQueue.main.async{
                    self.messagePublic.text = NSLocalizedString("Pour afficher la vitesse, autorisez l'app à accéder à la localisation : \nRéglages -> Condidentialité -> Service de localisation \nNB: l'app ne stocke pas votre position ; elle ne la transmet à personne", comment: "Si l'app n'est pas autorisée à accéder à la localisation")
                    //                    self.messageSecret.isHidden = false
                    self.affichageVitesse.text = ""
                    //                    self.imageLocalisation.isHidden = true
                    self.imagePasLocalisation.isHidden = false
                    //                    self.imageLocalisationPerdue.isHidden = true
                    self.roueAttente.stopAnimating()  //isHidden = true
                }
            case .notDetermined:
                print("not determined")
            default:
                print("défaut")
            //                locationManager.requestWhenInUseAuthorization()  // inopérant
            } // switch
        }  //  if (CLLocationManager.locationServicesEnabled())
        else {
            print("acces localisation pas ok pour le téléphone")
            //            print("􀘭")//accès localisation  pas ok")
            //            let alerte = UIAlertController(title: "Activez la localisation", message: "Pour afficher la vitesse, activez la localisation sur votre appareil : Réglages -> Condidentialité -> Service de localisation", preferredStyle: .alert)
            //            alerte.addAction(UIAlertAction(title: "OK", style: .default, handler: {_ in print("Alerte localisation validée")}))
            DispatchQueue.main.async{
                //                self.present(alerte, animated: true)
                self.messagePublic.text = NSLocalizedString("Pour afficher la vitesse, activez la localisation sur votre appareil : \nRéglages -> Condidentialité -> Service de localisation \nNB: l'app ne stocke pas votre position ; elle ne la transmet à personne", comment: "Si l'appareil n'est pas autorisé à lire la position")
                //                self.messageSecret.isHidden = false
                self.affichageVitesse.text = ""
                //                self.imageLocalisation.isHidden = true
                self.imagePasLocalisation.isHidden = false
                //                self.imageLocalisationPerdue.isHidden = true
                self.roueAttente.stopAnimating()  //isHidden = true
            }
        }
    }
    
    
    func afficherVitesse(vitesse: Double, precisionOK: Bool) {
        print("vitesse : \(vitesse) \(textesUnites[unite])")
        DispatchQueue.main.async{
            //            self.imageLocalisation.isHidden = true
            if ((vitesse >= 0) && precisionOK) {
                self.messagePublic.text = ""
                self.imagePasLocalisation.isHidden = true
                self.roueAttente.stopAnimating()  //isHidden = true
// //                self.affichageVitesse.text = String(format:"%.0f",vitesse)
                if Int(vitesse) <= 9 {
                    self.affichageVitesse.text = String(format:"\u{2007}%d", Int(vitesse))  // \u{2007} = blanc de même largeur qu'un chiffre
                    //                    let vitesseAAfficher = String(format:"%02d", Int(vitesse))
                    //                    let vitesseAAfficherMutable = NSMutableAttributedString(string: vitesseAAfficher)
                    //                    vitesseAAfficherMutable.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.black, range: NSMakeRange(0 , 1))
                    //                        self.affichageVitesse.attributedText = vitesseAAfficherMutable
                }
                else {
                        self.affichageVitesse.text = String(format:"%d", Int(vitesse))
                }
                localisationEstPerdue = false
                self.nombrePasOK = 0
            }
            else {
                if (self.imagePasLocalisation.isHidden) && (self.nombrePasOK >= 2) {
                self.affichageVitesse.text = ""
                self.roueAttente.startAnimating()  //isHidden = false
                print("pas de signal")
                }
                self.nombrePasOK = self.nombrePasOK + 1
            }
        }
    }
    
    
    //    CLLocationManagerDelegate
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let nombreLocations = locations.count
        let location:CLLocation = locations.last!
        //        let modeDeTransport = locationManager.activityType
        nombrePositionsLues = nombrePositionsLues + 1
        // au-delà de 12 heures en arrière-plan, on réinitialise le trajet
        if (location.timestamp.timeIntervalSince1970 - timeStampDernierePosition) > tempsAvantReinitialisationAuto {
            distanceTotaleSession = 0.0
            vitesseMaxSession = 0.0
            tempsSession = 0.0
            NotificationCenter.default.post(name : Notification.Name(notificationMiseAJourStats),object: nil)  // on prévient le ViewController d'actualiser l'affichage et d'enregistrer
        }
        let vitesseOK = (((location.speed >= 0) && (location.speed < 1)) || (location.course >= 0)) && ((location.timestamp.timeIntervalSince1970 - timeStampDernierePosition) < 2) && (nombrePositionsLues >= nbPositionsMiniAuDemarrage)
        //        if (locationManager.activityType == .automotiveNavigation) &&
        if(timeStampDernierePosition > 0.0) && (location.speed >= 1) && (distanceTotaleSession > distanceMiniAvantComptageTemps) {
            tempsSession = tempsSession + location.timestamp.timeIntervalSince1970 - timeStampDernierePosition
        }
        timeStampDernierePosition = location.timestamp.timeIntervalSince1970
        var laDistance = -3.33
        if vitesseOK {
            if (location.speed > vitesseMax) {vitesseMax = location.speed}
            if (location.speed > vitesseMaxSession) {vitesseMaxSession = location.speed}
            if !(locationPrecedente == nil) {
                laDistance =  location.distance(from: locationPrecedente)
                distanceTotale = distanceTotale + laDistance
                distanceTotaleSession = distanceTotaleSession + laDistance
                distanceTotale = max(distanceTotale, distanceTotaleSession)
            }
            locationPrecedente = location
            NotificationCenter.default.post(name : Notification.Name(notificationMiseAJourStats),object: nil)  // on prévient le ViewController d'actualiser l'affichage et d'enregistrer
            //            if ((distanceTotaleSession > distanceMiniAvantComptageTemps) && (premierTempsValide == 0)){
            //                premierTempsValide = location.timestamp.timeIntervalSince1970
            //            }
        }   // if vitesseOK
        
        afficherVitesse(vitesse: location.speed * facteurUnites[unite], precisionOK: vitesseOK)  // course (= le cap) est -1 la plupart du temps pendant que le système affine la localisaiton lorsqu'il vient d'avoir le droit d'y accéder
        let affichageSecret = String(format:"v %.2f ∆v %.1f, Ω %.1f, ∆x %.1f, \nd %.1f, t %.0f \nN %d", location.speed, location.speedAccuracy, location.course, location.horizontalAccuracy, laDistance, location.timestamp.timeIntervalSince1970,nombreLocations)
        //        switch locationManager.activityType{
        //        case .automotiveNavigation:
        //            affichageSecret.append(" Voiture")
        //        case .otherNavigation:
        //            affichageSecret.append(" Autre navigation")
        //        case .fitness:
        //            affichageSecret.append(" Fitness")
        //        case .airborne:
        //            affichageSecret.append(" Airborne")
        //        case .other:
        //            affichageSecret.append(" Autre")
        //        default:
        //            affichageSecret.append(" Inconnu")
        //        }
        DispatchQueue.main.async{
            self.messageDebug.text = affichageSecret
            //            self.messageSecret.isHidden = !debugMode
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        localisationEstPerdue = true
        DispatchQueue.main.async{
            //            self.messageSecret.isHidden = false
            self.messagePublic.text = NSLocalizedString("Erreur de localisation", comment: "Erreur de localisation")
            self.imagePasLocalisation.isHidden = false
        }
        print(error)
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        //        locationManager.requestWhenInUseAuthorization()
        gereDroitsLocalisation(origineViewDidLoad: false, origineViewDidAppear: false)
    }
    
    override func didReceiveMemoryWarning() {
        enregistrerStats()
    }
    
}

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


extension String {
    var floatValue: Float {
        return (self as NSString).floatValue
    }
}


//------------- Fonctions en réserve : gestion de l'orientation
//    @IBAction func basculeEnPaysage(){
//        AppDelegate.orientationLock = UIInterfaceOrientationMask.landscape
//        UIDevice.current.setValue(UIInterfaceOrientation.landscapeLeft.rawValue, forKey: "orientation")
//        UIViewController.attemptRotationToDeviceOrientation()
//    }
//
//    @IBAction func libereOrientation(){
//        AppDelegate.orientationLock = UIInterfaceOrientationMask.all
////        UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
//        UIViewController.attemptRotationToDeviceOrientation()
//    }



// ------------ Fonctions en réserve : test de la disponibilité du réseau GSM et/ou du réseau
//    // https://stackoverflow.com/questions/55737315/reportnewincomingcall-completion-not-called
//    // https://websitebeaver.com/callkit-swift-tutorial-super-easy
//    func nePasDerangerActif() -> Bool {  // original name : reportIncomingCall   // completion  // NE MARCHE PAS
//        let provider = CXProvider(configuration: CXProviderConfiguration(localizedName: "My App"))
//        var nePasDerangerEstActif = false
//        // 1.
//        let update = CXCallUpdate()
//        update.remoteHandle = CXHandle(type: .phoneNumber, value: "toto")
////        update.hasVideo = hasVideo
//
//        // 2.
//        provider.reportNewIncomingCall(with: UUID(), update: update) { error in
//                if error == nil {
//                    print("pas d'erreur")
//                    self.messageSecret.text = "pas d'erreur NPD"
////                // 3.
////                let call = Call(uuid: uuid, handle: handle)
////                self.callManager.add(call: call)
//            }
//                else{
//                    print("erreur")
//                    self.messageSecret.text = "Erreur"
//                    let erreur = error! as NSError
//                    if erreur.code == CXErrorCodeIncomingCallError.filteredByDoNotDisturb.rawValue {
//                        print("dnd")
//                        self.messageSecret.text = "Erreur NPD"
//                        nePasDerangerEstActif = true
//                    }
//                }
//
//            // 4.
////            completion?(error as NSError?)
//        }
//        return nePasDerangerEstActif
//    }
//
//
//
//
//    //    https://stackoverflow.com/questions/25623272/how-to-use-scnetworkreachability-in-swift
//    func connectedToNetwork() -> Bool {
//
//        var zeroAddress = sockaddr_in()
//        zeroAddress.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
//        zeroAddress.sin_family = sa_family_t(AF_INET)
//
//        guard let defaultRouteReachability = withUnsafePointer(to: &zeroAddress, {
//            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
//                SCNetworkReachabilityCreateWithAddress(nil, $0)
//            }
//        }) else {
//            return false
//        }
//
//        var flags: SCNetworkReachabilityFlags = []
//        if !SCNetworkReachabilityGetFlags(defaultRouteReachability, &flags) {
//            return false
//        }
//
//        let isReachable = flags.contains(.reachable)
//        let needsConnection = flags.contains(.connectionRequired)
//
//        return (isReachable && !needsConnection)
//    }

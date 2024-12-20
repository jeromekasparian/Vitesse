//
//  ViewController.swift
//  Vitesse
//
//  Created by Jérôme Kasparian on 25/04/2021.
//

/// feuille de route
// Localisation DE
// mettre un faux bouton refresh?
// Chrono basé sur les modes de transport https://stackoverflow.com/questions/56903624/swift-detect-motion-activity-in-background  https://developer.apple.com/documentation/coremotion/cmmotionactivity
// luminosité forcée // gestion avec le SceneDelegate ?

// - lisser davantage l'altitude ?

// - afficher dès qu’on a une vitesse nulle / Afficher sans mettre à jour les stats
// - Garder la localisation en arrière plan -> Déconnecter après un certain temps ? https://stackoverflow.com/questions/38971994/detect-if-the-application-in-background-or-foreground-in-swift


import UIKit
import CoreLocation
import CoreMotion
//import SystemConfiguration
//import CallKit

let autoriseDebug = true
@MainActor var debugMode: Bool = false
@MainActor var demoMode = false // pour faire les captures d'écran pour l'app store

//enum Etat {
//    case indetermine, pasDeLocalisation, initialisation, precisionInsuffisante, vitesseOK
//}
//var timeStampDernierEtat = 0.0
//var etatActuel : Etat = .indetermine

let keyUnite = "uniteAuDemarrage"
let keyVitesseMax = "vitesseMax"
let keyDistanceTotale = "distanceTotale"
let keyAutoriserAffichageTeteHaute = "autoriserAffichageTeteHaute"
let notificationMiseAJourStats = "miseAJourStats"
@MainActor var vitesseMax = 0.0
@MainActor var vitesseMaxSession = 0.0
@MainActor var distanceTotale = 0.0
@MainActor var distanceTotaleSession = 0.0
@MainActor var denivelePositifSession = 0.0
@MainActor var deniveleNegatifSession = 0.0
@MainActor var tempsSession = 0.0  // le temps total de trajet, en secondes
let penteMaximaleCredible: Double = 0.3

//var premierTempsValide = 0.0
let precisionVerticaleMinimale: Double = 10.0 // précision minimale sur l'altitude pour qu'on la prenne en compte
@MainActor var unite: Int = 1 // par défaut, km/h
let textesUnites: [String] = [NSLocalizedString("m/s", comment: "vistesse : m/s"), NSLocalizedString("km/h", comment: "vitesse : km/h"), NSLocalizedString("mph", comment: "vitesse : mph")]
let facteurUnites: [Double] = [1.0, 3.6, 2.2369362920544]
let textesUnitesDistance: [String] = [NSLocalizedString("m", comment: "distance : m"), NSLocalizedString("km", comment: "distance : km"), NSLocalizedString("mi", comment: "distance : mi")]
let textesUnitesAltitude: [String] = [" " + NSLocalizedString("m", comment: "m"), " " + NSLocalizedString("m", comment: "m"),NSLocalizedString("'", comment: "pied") + " "]

let facteurUnitesDistance: [Double] = [1.0, 0.001, 0.00062137]
let facteurUnitesAltitude: [Double] = [1.0, 1.0, 3.2808]
@MainActor var nombrePositionsLues = 0
@MainActor var timeStampDernierePosition = 0.0
@MainActor var luminositeEcranSysteme = UIScreen.main.brightness //CGFloat(0.0)
@MainActor var luminositeEstForcee = false
let autoriseAffichageTeteHauteBlanc = false
@MainActor var autoriserAffichageTeteHaute = true
let tempsMaxEntrePositions = 5.0 // temps en secondes au-delà duquel on considère qu'on a perdu la position
let nbPositionsMiniAuDemarrage = 5 // nombre de positions qu'on lit avant de les prendre en compte.
@MainActor var statsEstOuvert = false
let tempsAvantReinitialisationAuto: Double = 3600 * 12 // temps en secondes au-delà duquel on réinitialise les stats de trajet
@MainActor var localisationEstPerdue = false
//let distanceMiniAvantComptageTemps = 15.0  // on considère qu'on est en marche si on a parcouru au moins 30 m
@MainActor let userDefaults = UserDefaults.standard
let vitesseMiniPourActiverCompteur = 0.2 // m/s : vitesse en-dessous de laquelle on considère qu'on est immobile
//var nomActiviteEnCours = "Init"
@MainActor var locationToujoursAutorisee: Bool = false
let dureeMaxiTunnel: Double = 3600 // secondes : temps maxi pendant lequel on peut perdre la localisation et, à l'arriver, incrémenter la distance, la durée et le dénivelé.
//let distanceMaxiPourStopperBackground = 100 // m : si on a bougé de moins de 100 m en 1 heure et qu'on est resté en fond, on arrête d'actualiser la position.


class ViewController: UIViewController, @preconcurrency CLLocationManagerDelegate {
    
    var locationManager: CLLocationManager! = CLLocationManager()
    //    let activityManager = CMMotionActivityManager()
    //    let inclinaisonMin = 5.0 // inclinaison min en degres (sur le roulis) pour dire qu'on est en mode tête haute
    let inclinaisonMax = 38.0 // inclinaison max en degres (sur le roulis) pour dire qu'on est en mode tête haute
    let radiansEnDegres = 180.0 / 3.14159
    var positionTeteHaute: Bool = false
    var anciennePositionTeteHaute: Bool = false
    var locationPrecedente: CLLocation! = nil
    var altitudePrecedente: Double = .nan
    var altitudeActuelle: Double = .nan
    var distancePourAltitudeActuelle: Double = .nan
    var nombreAltitudesMoyennees: Int = 0
    var affichageTeteHauteBlanc = false
    var timer = Timer()
    var nombrePasOK = 0 // nombre de vitesses pas ok reçues à la suite
    //    var timeStampEntreeBackground: Double = .nan
    //    var positionEntreeBackground: CLLocation! = nil
    
    let motionManager = CMMotionManager()
    var dateDernierBoutonReactiveChevron = Date()
    let tempsMiniAffichageChevron: Double = 10.0  // secondes
    let vitesseMiniPourCacherChevron: Double = 3.0 // m/s
    let luminositeMinimalePourForcerAffichageBlanc: Double = 0.8
    
    @IBOutlet weak var affichageVitesse: UILabel!
    @IBOutlet weak var gabaritAffichageVitesse: UILabel!
    @IBOutlet var affichageUnite: UIButton!
    @IBOutlet var imagePasLocalisation: UIImageView!
    @IBOutlet var roueAttente: UIActivityIndicatorView!
    @IBOutlet var messagePublic: UILabel!
    @IBOutlet var messageDebug: UILabel!  // caché dans l'interface - utile pour les tests de début
    @IBOutlet var boutonOuvreStats: UIButton!
    @IBOutlet var labelPente: UILabel!
    @IBOutlet var boutonReactiveChevron: UIButton!
    
    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }
    
    @IBAction func changeUnite () {
        unite = (unite + 1) % 3
        userDefaults.set(unite, forKey: keyUnite)
        affichageUnite.setTitle(textesUnites[unite], for: .normal) // = textesUnites[unite]
        if (affichageVitesse.text != "") {
            let laVitesse = Double(affichageVitesse.text?.floatValue ?? -1.0)
            afficherVitesse(vitesse: laVitesse, precisionOK: true, pente: .nan)
        }
    }
    
    @IBAction func boutonReactiveChevronAppuye(){
        dateDernierBoutonReactiveChevron = Date()
        if boutonOuvreStats.isHidden {
            DispatchQueue.main.async {
                self.boutonOuvreStats.isHidden = false
            }
        }
    }
    
    @objc func ouvreStats() {
        //        print("perform segue")
        effaceStatsSiTropVieilles()
        performSegue(withIdentifier:"OuvreStats", sender: self)
    }
    
    @objc func changeDebugMode() {
        debugMode = !debugMode
        DispatchQueue.main.async{
            self.messageDebug.isHidden = !debugMode
            self.labelPente.isHidden = !debugMode
        }
    }
    
    @objc func changeDemoMode() {
        demoMode = !demoMode
    }
    
    @objc func changeCouleurTeteHaute() {
        if autoriseAffichageTeteHauteBlanc{
            affichageTeteHauteBlanc = !affichageTeteHauteBlanc
        }
    }
    
    override func viewDidLoad() {
        //        justLoaded = true
        debugMode = debugMode && autoriseDebug
        if #available(iOS 13.0, *) {
            roueAttente.style = .large
        } else {
            imagePasLocalisation.image = UIImage(named: "location.slash.fill")
        }
        DispatchQueue.main.async{
            self.boutonReactiveChevron.setTitle("", for: .normal)
            self.messagePublic.text = ""
            self.messageDebug.isHidden = !debugMode
            self.labelPente.isHidden = !debugMode
            self.labelPente.text = ""
            self.labelPente.font = UIFont.monospacedDigitSystemFont(ofSize: self.labelPente.font.pointSize, weight: .regular)
            self.messageDebug.font = UIFont.monospacedDigitSystemFont(ofSize: self.messageDebug.font.pointSize, weight: .regular)
            self.affichageVitesse.text = ""
            self.adapterTailleAffichageVitesse()
            unite = userDefaults.value(forKey: keyUnite) as? Int ?? 1
            self.affichageUnite.setTitle(textesUnites[unite], for: .normal)
            vitesseMax = userDefaults.value(forKey: keyVitesseMax) as? Double ?? 0.0
            distanceTotale = userDefaults.value(forKey: keyDistanceTotale) as? Double ?? 0.0
            self.imagePasLocalisation.isHidden = true
            self.roueAttente.startAnimating()
        }
        //        etatActuel = .indetermine
        // mise en place de la détection du swipe up pour ouvrir le tiroir des stats
        let swipeHaut = UISwipeGestureRecognizer(target:self, action: #selector(ouvreStats))
        swipeHaut.direction = UISwipeGestureRecognizer.Direction.up
        self.view.addGestureRecognizer(swipeHaut)
        
        // mise en place de la détection du swipe left à 3 doigts pour activer le mode debug
        let swipeDebug = UISwipeGestureRecognizer(target:self, action: #selector(changeDebugMode))
        swipeDebug.direction = UISwipeGestureRecognizer.Direction.left
        swipeDebug.numberOfTouchesRequired = 3
        self.view.addGestureRecognizer(swipeDebug)
        
        // mise en place de la détection du swipe left à 3 doigts pour activer le mode debug
        let swipeDemo = UISwipeGestureRecognizer(target:self, action: #selector(changeDemoMode))
        swipeDemo.direction = UISwipeGestureRecognizer.Direction.right
        swipeDemo.numberOfTouchesRequired = 3
        self.view.addGestureRecognizer(swipeDemo)
        
        if autoriseAffichageTeteHauteBlanc{
            // mise en place de la détection du swipe right à 3 doigts pour activer le mode tête haute blanc
            let swipeBlanc = UISwipeGestureRecognizer(target:self, action: #selector(self.changeCouleurTeteHaute))
            swipeBlanc.direction = UISwipeGestureRecognizer.Direction.right
            swipeBlanc.numberOfTouchesRequired = 3
            self.view.addGestureRecognizer(swipeBlanc)
        }
        
        motionManager.deviceMotionUpdateInterval = 1
        NotificationCenter.default.addObserver(self, selector: #selector(gereDroitsLocationDepuisNotification), name: UIApplication.didBecomeActiveNotification, object: nil)
        // Get attitude orientation
        motionManager.startDeviceMotionUpdates(to: .main, withHandler: gereOrientation) //{ (motion, error) in
        
        //        NotificationCenter.default.addObserver(self, selector: #selector(appMovedToBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
        //        NotificationCenter.default.addObserver(self, selector: #selector(appMovedToForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
        
        UIApplication.shared.isIdleTimerDisabled = true
        
        boutonOuvreStats.setTitle("", for: .normal)
        if #available(iOS 13.0, *) {
            boutonOuvreStats.setImage(UIImage(systemName: "chevron.compact.up", withConfiguration: UIImage.SymbolConfiguration(pointSize: 48)), for: .normal)
        } else {
            // Fallback on earlier versions
            boutonOuvreStats.setImage(UIImage(named: "chevron.compact.up"), for: .normal)
        }
        let alert = UIAlertController(title: NSLocalizedString("Pour votre sécurité", comment: "Titre alerte"), message: NSLocalizedString("avant de conduire, assurez-vous que le mode Avion ou \"Ne pas déranger en voiture\" est activé", comment: "Contenu de l'alerte de sécurité"), preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "bouton OK"), style: .default, handler: {_ in self.gereDroitsLocalisation(origineViewDidLoad: true, origineViewDidAppear: false)}))
        DispatchQueue.main.async{
            if (distanceTotale > 0) || (vitesseMax > 0){  // Transition : si on a déjà utilisé l'app, on garde le comportement précédent...
                autoriserAffichageTeteHaute = userDefaults.value(forKey: keyAutoriserAffichageTeteHaute) as? Bool ?? true
            }
            else { // ... sinon par défaut on désactive le mode miroir au premier lancement.
                autoriserAffichageTeteHaute = userDefaults.value(forKey: keyAutoriserAffichageTeteHaute) as? Bool ?? false
            }
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
    
    //    @objc func appMovedToBackground() {  // pas complet
    //        timeStampEntreeBackground = Date().timeIntervalSince1970
    //        positionEntreeBackground = locationPrecedente
    //    }
    //
    //    @objc func appMovedToForeground() {  // pas complet
    //        timeStampEntreeBackground = .nan
    //        positionEntreeBackground = nil
    //    }
    
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
    
    func effaceStatsSiTropVieilles() {
        if (timeStampDernierePosition > 0.0) && ((Date().timeIntervalSince1970 - timeStampDernierePosition) > tempsAvantReinitialisationAuto) {
            effacerStats()
            locationPrecedente = nil
            altitudePrecedente = .nan
            altitudeActuelle = .nan
            distancePourAltitudeActuelle = .nan
            nombreAltitudesMoyennees = 0
            timeStampDernierePosition = 0.0
        }
    }
    
    @objc func verifieQueLocalisationEstActive() {
        effaceStatsSiTropVieilles()
        
        if ((Date().timeIntervalSince1970 -  timeStampDernierePosition)  > tempsMaxEntrePositions) {
            localisationEstPerdue = true
            DispatchQueue.main.async{
                if demoMode{
                    self.roueAttente.stopAnimating()
                    self.afficherVitesse(vitesse: 1, precisionOK: true, pente: .nan)
                }
                else {
                    //                    self.messageSecret.isHidden = false
                    var leMessage =  NSLocalizedString("Localisation perdue", comment:"Localisation perdue")
                    if #available(iOS 14.0, *) {
                        if self.locationManager.accuracyAuthorization == .reducedAccuracy{
                            leMessage = NSLocalizedString("Précision réduite", comment: "Basse précision autorisée")
                        }
                    }
                    self.messagePublic.text = leMessage
                    self.affichageVitesse.text = ""
                    self.affichePictoPasLocalisation()
                }
            }
        }
    }
    
    func affichePictoPasLocalisation() {
        if ((Date().timeIntervalSince1970 -  timeStampDernierePosition).truncatingRemainder(dividingBy: 15.0)  > tempsMaxEntrePositions) { // on met la roulette 5 secondes toutes les 15 secondes
            self.imagePasLocalisation.isHidden = false
            self.roueAttente.stopAnimating()
        } else{
            self.imagePasLocalisation.isHidden = true
            self.roueAttente.startAnimating()
        }
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        enregistrerStats()
        stoppeLuminositeMax()
//        if luminositeEstForcee {
//            UIScreen.main.brightness = luminositeEcranSysteme
//            self.messageDebug.textColor = .green
//        }
//        luminositeEstForcee = false
        timer.invalidate()
        super.viewWillDisappear(true)
    }
    
    
    func gereOrientation(motion:CMDeviceMotion?,error:Error?) {
        let tangage = motion!.attitude.pitch * radiansEnDegres  // basculement vers l'avant
        let roulis = motion!.attitude.roll * radiansEnDegres    // basculement vers le côté
        let commencerPositionTeteHaute = (abs(roulis) < inclinaisonMax) && (abs(roulis) > abs(tangage)) && (UIWindow.isLandscape) && autoriserAffichageTeteHaute // UIDevice.current.orientation.isLandscape est l'orientation physique de l'appareil, quand on est plus ou moins à plat il dit "à plat"
        let arreterPositionTeteHaute = (abs(roulis) > inclinaisonMax + 5.0) || (abs(roulis + 5.0) < abs(tangage))
        if commencerPositionTeteHaute {positionTeteHaute = true} else if arreterPositionTeteHaute {positionTeteHaute = false}
        DispatchQueue.main.async{
            if (self.positionTeteHaute != self.anciennePositionTeteHaute) {
                self.affichageVitesse.flipX()
                self.affichageUnite.flipX()
                switch self.affichageUnite.contentHorizontalAlignment {
                case .left: self.affichageUnite.contentHorizontalAlignment = .right
                case .right: self.affichageUnite.contentHorizontalAlignment = .left
                    //                    case .leading: self.affichageUnite.contentHorizontalAlignment = .trailing
                    //                    case .trailing: self.affichageUnite.contentHorizontalAlignment = .leading
                default: print("cas par défaut")
                }
                self.anciennePositionTeteHaute = self.positionTeteHaute
            } // position a changé
            if self.positionTeteHaute {  // le téléphone est à plat -> on affiche le texte en blanc pour réflexion sur le pare-brise
                if self.affichageTeteHauteBlanc {
                    self.affichageVitesse.textColor = .black
                    self.affichageVitesse.backgroundColor = .white
                    self.affichageUnite.setTitleColor(self.affichageVitesse.textColor, for: .normal)
                    self.affichageUnite.backgroundColor = self.affichageVitesse.backgroundColor
                }
                else {
                    self.affichageVitesse.textColor = .white
                    self.affichageUnite.setTitleColor(self.affichageVitesse.textColor, for: .normal)
                    
                }
                // on force l'écran à rester en mode portrait
                if !luminositeEstForcee && !statsEstOuvert && UIApplication.shared.applicationState == .active { //isUserInteractionEnabled { // && self.view.isFirstResponder)
                    luminositeEcranSysteme = UIScreen.main.brightness   // on note la luminosité de l'écran, pour pouvoir y revenir plus tard
                    UIScreen.main.brightness = CGFloat(1.0)  // on met le contraste au max
                    self.messageDebug.textColor = .yellow
                    luminositeEstForcee = true
                }
            }  // téléphone à plat -> position tête haute
            else { // le téléphone est penché -> on affiche le texte en gris pour lecture directe
                if luminositeEstForcee && UIApplication.shared.applicationState == .active { // on revient au contraste par défaut du système
                    stoppeLuminositeMax()
//                    self.messageDebug.textColor = .red
                }
                self.affichageVitesse.textColor = UIScreen.main.brightness >= self.luminositeMinimalePourForcerAffichageBlanc ? .white : .lightGray
                if self.affichageTeteHauteBlanc {
                    self.affichageVitesse.backgroundColor = .black
                    self.affichageUnite.backgroundColor = self.affichageVitesse.backgroundColor
                }
                self.affichageUnite.setTitleColor(self.affichageVitesse.textColor, for: .normal)
            }  // téléphone dressé
        } // DispatchQueue.main.async
    }
    
    @objc func gereDroitsLocationDepuisNotification() {
        gereDroitsLocalisation(origineViewDidLoad : false, origineViewDidAppear: false)
    }
    
    @objc func gereDroitsLocationDepuisViewDidLoad() {
        gereDroitsLocalisation(origineViewDidLoad : true, origineViewDidAppear: false)
    }
    
    func gereDroitsLocalisation(origineViewDidLoad : Bool, origineViewDidAppear: Bool) {
        print("lancement viewDidLoad : \(origineViewDidLoad)")
        print("lancement viewDidAppear : \(origineViewDidAppear)")
        
        locationManager.delegate = self
        
        if (CLLocationManager.locationServicesEnabled()) { // la localisation est activée sur l'appareil
            print("droits de localisation : ", CLLocationManager.authorizationStatus().rawValue)
            //            locationManager.requestWhenInUseAuthorization()
            locationManager.requestAlwaysAuthorization()
            let statut = CLLocationManager.authorizationStatus()
            switch statut {
            case .authorizedAlways, .authorizedWhenInUse:  // l'app a l'autorisation d'accéder à la localisation
                locationToujoursAutorisee = statut == .authorizedAlways
                locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
                if statut == .authorizedAlways {
                    locationManager.allowsBackgroundLocationUpdates = true
                    locationManager.pausesLocationUpdatesAutomatically = true // après un certain temps sans bouger, il arrête les mises à jour de la localisation en tâche de fond.
                    locationManager.activityType = .otherNavigation
                    if #available(iOS 11.0, *) {
                        locationManager.showsBackgroundLocationIndicator = true
                    }
                }
                locationManager.startUpdatingLocation()
                //            self.imagePasDeVitesse.image = UIImage(systemName: "location.fill")
                DispatchQueue.main.async{
                    if statut == .authorizedAlways {
                        self.messageDebug.text = "Localisation autorisée toujours"
                        print("acces localisation toujours ok")
                    } else {
                        self.messageDebug.text = "Localisation autorisée app active"
                        print("acces localisation app active ok")
                        
                    }
                    //                    if self.imagePasLocalisation.isHidden {
                    self.affichageVitesse.text = ""
                    self.affichePictoPasLocalisation()
                    //                        self.roueAttente.startAnimating()  //isHidden = true
                    //                    }
                }
            case .denied, .restricted:
                print("acces localisation pas ok pour l'app")
                locationToujoursAutorisee = false
                DispatchQueue.main.async{
                    let leMessage = NSLocalizedString("Pour afficher la vitesse, autorisez l'app à accéder à la localisation \nNB: l'app ne stocke pas votre position ; elle ne la transmet à personne", comment: "Si l'app n'est pas autorisée à accéder à la localisation")
                    self.afficherAlerteRenvoiPreferences(titre: NSLocalizedString("Autorisez la localisation", comment: "Titre de l'alerte"), message: leMessage, perfsDeLApp: true)
                    self.affichageVitesse.text = ""
                    self.affichePictoPasLocalisation()
                }
            case .notDetermined:
                print("not determined")
                locationToujoursAutorisee = false
            default:
                print("défaut")
                locationToujoursAutorisee = false
            } // switch
        }  //  if (CLLocationManager.locationServicesEnabled())
        else {
            print("acces localisation pas ok pour le téléphone")
            locationToujoursAutorisee = false
            DispatchQueue.main.async{
                //                self.present(alerte, animated: true)
                let leMessage = NSLocalizedString("Pour afficher la vitesse, activez la localisation sur votre appareil \nNB: l'app ne stocke pas votre position ; elle ne la transmet à personne", comment: "Si l'appareil n'est pas autorisé à lire la position")
                self.afficherAlerteRenvoiPreferences(titre: NSLocalizedString("Autorisez la localisation", comment: "Titre de l'alerte"), message: leMessage, perfsDeLApp: false)
                self.affichageVitesse.text = ""
                self.affichePictoPasLocalisation()
            }
        }
    }
    
    
    func afficherVitesse(vitesse: Double, precisionOK: Bool, pente: Double) {
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
                }
                else {
                    self.affichageVitesse.text = String(format:"%d", Int(vitesse))
                }
                if pente.isNaN || abs(pente) < 0.01 || abs(pente) > penteMaximaleCredible {
                    self.labelPente.text = ""
                } else {
                    let flechePente = pente > 0 ? "➚" : "➘"
                    self.labelPente.text = String(format: flechePente + " %2.0f%%", abs(pente) * 100.0).replacingOccurrences(of: " ", with: "\u{2007}")
                }
                localisationEstPerdue = false
                self.nombrePasOK = 0
            }  // Vitesse > 0 et precisionOK
            else {
                //                if (self.imagePasLocalisation.isHidden) && (self.nombrePasOK >= 2) {
                if (self.nombrePasOK >= 1) {
                    self.affichageVitesse.text = ""
                    self.affichePictoPasLocalisation()
                    self.labelPente.text = ""
                    //                    self.roueAttente.startAnimating()  //isHidden = false
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
        var laVitesseLue = location.speed
        nombrePositionsLues = nombrePositionsLues + 1
        // au-delà de 12 heures en arrière-plan, on réinitialise le trajet
        if (location.timestamp.timeIntervalSince1970 - timeStampDernierePosition) > tempsAvantReinitialisationAuto {
            effacerStats()
        }
        let vitesseOK = (((laVitesseLue >= 0) && (laVitesseLue < 1)) || (location.course >= 0))
        && ((location.timestamp.timeIntervalSince1970 - timeStampDernierePosition) < dureeMaxiTunnel)
        && ((nombrePositionsLues >= nbPositionsMiniAuDemarrage) || (location.horizontalAccuracy <= 10))
        if #available(iOS 10.0, *) {
            laVitesseLue = (laVitesseLue >= 0 && location.speedAccuracy > 0 && laVitesseLue > 0.5 * location.speedAccuracy) ? laVitesseLue : 0.0
        }  // si la vitesse est plus petite que l'incertitude on la met à zéro
        var laDistance = -3.33
        var pente: Double = .nan
        if vitesseOK {
            
            if locationPrecedente != nil && !altitudePrecedente.isNaN && laVitesseLue > vitesseMiniPourActiverCompteur && timeStampDernierePosition > 0.0 { //&& distanceTotaleSession > distanceMiniAvantComptageTemps {
                laDistance =  location.distance(from: locationPrecedente)
                distanceTotale = distanceTotale + laDistance
                distanceTotaleSession = distanceTotaleSession + laDistance
                distanceTotale = max(distanceTotale, distanceTotaleSession)
                tempsSession = tempsSession + location.timestamp.timeIntervalSince1970 - timeStampDernierePosition
                if (laVitesseLue > vitesseMax) {vitesseMax = laVitesseLue}
                if (laVitesseLue > vitesseMaxSession) {vitesseMaxSession = laVitesseLue}
            }
            NotificationCenter.default.post(name : Notification.Name(notificationMiseAJourStats),object: nil)  // on prévient le ViewController d'actualiser l'affichage et d'enregistrer
        } // if vitesseOK
        if location.verticalAccuracy <= precisionVerticaleMinimale {
            if altitudeActuelle.isNaN {
                altitudeActuelle = location.altitude
                distancePourAltitudeActuelle = laDistance
                nombreAltitudesMoyennees = 1
            } else if nombreAltitudesMoyennees <= 10 {
                altitudeActuelle = (location.altitude + (altitudeActuelle * Double(nombreAltitudesMoyennees))) / Double(nombreAltitudesMoyennees + 1)
                distancePourAltitudeActuelle = (laDistance + (distancePourAltitudeActuelle * Double(nombreAltitudesMoyennees))) / Double(nombreAltitudesMoyennees + 1)
                nombreAltitudesMoyennees = nombreAltitudesMoyennees + 1
            } else {
                altitudeActuelle = 0.1 * location.altitude + 0.9 * altitudeActuelle // moyenne glissante avec amortissement, pour "lisser" les fluctuations de l'altitude
                distancePourAltitudeActuelle = 0.1 * laDistance + 0.9 * distancePourAltitudeActuelle // moyenne glissante avec amortissement, pour "lisser" les fluctuations de l'altitude
                nombreAltitudesMoyennees = nombreAltitudesMoyennees + 1
            }
            if vitesseOK {
                let denivele = altitudeActuelle - altitudePrecedente
                if abs(denivele) <= laDistance * penteMaximaleCredible && nombreAltitudesMoyennees >= 10 {
                    if denivele > 0 {
                        denivelePositifSession = denivelePositifSession + denivele
                    } else {
                        deniveleNegatifSession = deniveleNegatifSession - denivele
                    }
                    pente = denivele / laDistance
                }
            } // if vitesseOK
        }
        afficherVitesse(vitesse: laVitesseLue * facteurUnites[unite], precisionOK: vitesseOK, pente: pente)  // course (= le cap) est -1 la plupart du temps pendant que le système affine la localisaiton lorsqu'il vient d'avoir le droit d'y accéder
        print("temps", Date().timeIntervalSince(dateDernierBoutonReactiveChevron))
        if laVitesseLue > vitesseMiniPourCacherChevron && Date().timeIntervalSince(dateDernierBoutonReactiveChevron) > tempsMiniAffichageChevron && !boutonOuvreStats.isHidden {
            DispatchQueue.main.async {
                self.boutonOuvreStats.isHidden = true
            }
        } else if laVitesseLue < 0.2 && vitesseOK && boutonOuvreStats.isHidden {
            DispatchQueue.main.async {
                self.boutonOuvreStats.isHidden = false
            }
        }
        var affichageSecret = ""
        if #available(iOS 10.0, *) {
            affichageSecret = String(format:"v %.2f ∆v %.1f, Ω %.1f, ∆x %.1f, \nd %.1f, t %d ∆t %.0f N %d\nh %.2f ∆h %.0f ➚ %.2f <h> %.2f", location.speed, location.speedAccuracy, location.course, location.horizontalAccuracy, laDistance, Int(location.timestamp.timeIntervalSince1970) % 1000, location.timestamp.timeIntervalSince1970 - timeStampDernierePosition, nombreLocations, location.altitude, location.verticalAccuracy, altitudeActuelle - altitudePrecedente, altitudeActuelle)
        } else { // Fallback on earlier versions
            affichageSecret = String(format:"v %.2f ∆v %.1f, Ω %.1f, ∆x %.1f, \nd %.1f, t %d ∆t %.0f N %d\nh %.2f ∆h %.0f ➚ %.2f <h> %.2f", location.speed, location.course, location.horizontalAccuracy, laDistance, Int(location.timestamp.timeIntervalSince1970) % 1000, location.timestamp.timeIntervalSince1970 - timeStampDernierePosition, nombreLocations, location.altitude, location.verticalAccuracy, altitudeActuelle - altitudePrecedente, altitudeActuelle)
        }
        affichageSecret = affichageSecret + String(format: "\nv %.1f m/s t %.1f s", laVitesseLue, Date().timeIntervalSince(dateDernierBoutonReactiveChevron))
        locationPrecedente = location
        altitudePrecedente = altitudeActuelle
        timeStampDernierePosition = location.timestamp.timeIntervalSince1970
        DispatchQueue.main.async{
            self.messageDebug.text = affichageSecret
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        localisationEstPerdue = true
        if CLLocationManager.locationServicesEnabled() { // la localisation est activée sur l'appareil
            if CLLocationManager.authorizationStatus() != .denied && CLLocationManager.authorizationStatus() != .restricted {
                DispatchQueue.main.async{
                    //            self.messageSecret.isHidden = false
                    self.messagePublic.text = NSLocalizedString("Erreur de localisation", comment: "Erreur de localisation")
                    self.affichageVitesse.text = ""
                    self.affichePictoPasLocalisation()
                    //            self.imagePasLocalisation.isHidden = false
                }
            }
        }
        print(error)
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        gereDroitsLocalisation(origineViewDidLoad: false, origineViewDidAppear: false)
    }
    
    override func didReceiveMemoryWarning() {
        enregistrerStats()
    }
    
    func effacerStats() {
        distanceTotaleSession = 0.0
        vitesseMaxSession = 0.0
        denivelePositifSession = 0.0
        deniveleNegatifSession = 0.0
        tempsSession = 0.0
        NotificationCenter.default.post(name : Notification.Name(notificationMiseAJourStats),object: nil)  // on prévient le ViewController d'actualiser l'affichage et d'enregistrer
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

extension UIViewController {
    func afficherAlerteRenvoiPreferences(titre: String, message: String, perfsDeLApp: Bool) {
        DispatchQueue.main.async {
            //        let changePrivacySetting = "AVCam doesn't have permission to use the camera, please change privacy settings"
            //        let message = NSLocalizedString(changePrivacySetting, comment: "Alert message when the user has denied access to the camera")
            //            let titre = NSLocalizedString("Autorisez la localisation", comment: "Titre de l'alerte")
            let alertController = UIAlertController(title: titre, message: message, preferredStyle: .alert)
            if #available(iOS 10.0, *) {
                alertController.addAction(UIAlertAction(title: NSLocalizedString("Annuler", comment: "Alert Cancel button"), style: .cancel, handler: nil))
                var urlAOuvrir: URL
                if perfsDeLApp {
                    urlAOuvrir = URL(string: UIApplication.openSettingsURLString)!  // url pour ouvrir les préférences de l'app appelante
                } else {
                    urlAOuvrir = URL(string:"App-Prefs::root=Settings&path=General")!  // url pour ouvrir les l'app Préférences : à la racine sauf si elle est déjà ouverte sur une sous-page. A noter que c'est manifestement une url pas 100% publique de la part d'Apple, donc susceptible de dysfonctionner à l'avenir.
                }
                alertController.addAction(UIAlertAction(title: NSLocalizedString("Settings", comment: "Alert button to open Settings"), style: .`default`, handler: { _ in
                                    UIApplication.shared.open(urlAOuvrir, options: [:], completionHandler: nil)
                                }))
            } else {  // iOS 9
                alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "OK"), style: .cancel, handler: nil))
            }
            DispatchQueue.main.async {
                self.present(alertController, animated: true, completion: nil)
            }
        }
    }
    
}

extension String {
    var floatValue: Float {
        return (self as NSString).floatValue
    }
}


extension UIWindow {
    static var isLandscape: Bool {
        if #available(iOS 13.0, *) {
            return UIApplication.shared.windows
                .first?
                .windowScene?
                .interfaceOrientation
                .isLandscape ?? false
        } else {
            return UIApplication.shared.statusBarOrientation.isLandscape
        }
    }
}

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

//enum Etat {
//    case indetermine, pasDeLocalisation, initialisation, precisionInsuffisante, vitesseOK
//}
//var timeStampDernierEtat = 0.0
//var etatActuel : Etat = .indetermine

let keyUnite = "uniteAuDemarrage"
let keyVitesseMax = "vitesseMax"
let keyDistanceTotale = "distanceTotale"
let keyAutoriserAffichageTeteHaute = "autoriserAffichageTeteHaute"
//let notificationMiseAJourStats = "miseAJourStats"
let keyEnregistrerStats = "keyEnregistrerStats"
let keyMontrerAlerteDemarrage = "keyMontrerAlerteDemarrage"
let nomSegueOuvreStats = "OuvreStats"

  // le temps total de trajet, en secondes
let penteMaximaleCredible: Double = 0.3
let penteMinimalePourAffichage: Double = 0.02
let distanceMiniPourPente: Double = 0.3

//var premierTempsValide = 0.0
let precisionVerticaleMinimale: Double = 10.0 // précision minimale sur l'altitude pour qu'on la prenne en compte
let precisionHorizontaleMinimalePourAltitudeOpenTopo: Double = 10.0 // m
let textesUnites: [String] = [NSLocalizedString("m/s", comment: "vistesse : m/s"), NSLocalizedString("km/h", comment: "vitesse : km/h"), NSLocalizedString("mph", comment: "vitesse : mph"), NSLocalizedString("kt", comment: "vitesse : nœuds")]
let textesUnitesDistance: [String] = [NSLocalizedString("km", comment: "distance : m"), NSLocalizedString("km", comment: "distance : km"), NSLocalizedString("mi", comment: "distance : mi"), NSLocalizedString("nm", comment: "distance : miles nautiques")]
let textesUnitesAltitude: [String] = [" " + NSLocalizedString("m", comment: "m"), " " + NSLocalizedString("m", comment: "m"), NSLocalizedString("'", comment: "pied") + " ", NSLocalizedString("'", comment: "pied") + " "]

let facteurUnitesVitesses: [Double] = [1.0, 3.6, 2.2369362920544, 1.94552529]
let facteurUnitesDistance: [Double] = [0.001, 0.001, 0.00062137, 0.00053996]
let facteurUnitesAltitude: [Double] = [1.0, 1.0, 3.2808, 3.2808]

let autoriseAffichageTeteHauteBlanc = false
let tempsMaxEntrePositions = 5.0 // temps en secondes au-delà duquel on considère qu'on a perdu la position
let nbPositionsMiniAuDemarrage = 5 // nombre de positions qu'on lit avant de les prendre en compte.
let tempsAvantReinitialisationAuto: Double = 3600 * 12 // temps en secondes au-delà duquel on réinitialise les stats de trajet
let vitesseMiniPourActiverCompteur = 0.2 // m/s : vitesse en-dessous de laquelle on considère qu'on est immobile
let dureeMaxiTunnel: Double = 3600 // secondes : temps maxi pendant lequel on peut perdre la localisation et, à l'arriver, incrémenter la distance, la durée et le dénivelé.
@MainActor var luminositeEcranSysteme = UIScreen.main.brightness //CGFloat(0.0)
@MainActor var luminositeEstForcee = false
let radiansEnDegres = 180.0 / 3.14159
let degresEnRadians = Double.pi / 180.0
let pointsPourPente: Int = 10

class ViewController: UIViewController, @MainActor CLLocationManagerDelegate, @MainActor StatsModalDelegate {
    
    
    var debugMode: Bool = false
    var demoMode = false // pour faire les captures d'écran pour l'app store

    var locationManager: CLLocationManager! = CLLocationManager()
    let inclinaisonMax = 38.0 // inclinaison max en degres (sur le roulis) pour dire qu'on est en mode tête haute

    var positionTeteHaute: Bool = false
    var anciennePositionTeteHaute: Bool = false
    var locationPrecedente: CLLocation?
    var altitudePrecedente10: Double = .nan
    var altitudePrecedente: Double = .nan
    
    let nombreAltitudesAMoyenner: Int = 40
    var affichageTeteHauteBlanc = false
    var timer = Timer()
    var nombrePasOK = 0 // nombre de vitesses pas ok reçues à la suite
    
    let motionManager = CMMotionManager()
    var dateDernierBoutonReactiveChevron = Date()
    let tempsMiniAffichageChevron: Double = 10.0  // secondes
    let vitesseMiniPourCacherChevron: Double = 3.0 // m/s
    let luminositeMinimalePourForcerAffichageBlanc: Double = 0.8
    var nombrePositionsLues = 0
    var timeStampDernierePosition = 0.0
    var localisationEstPerdue = false
    var montrerAlerteDemarrage: Bool = true
    
    var stats = Stats()
    var unite: Int = 1 // par défaut, km/h
    var autoriserAffichageTeteHaute = true
//    var statsEstOuvert = false
    let userDefaults = UserDefaults.standard
    var locationToujoursAutorisee: Bool = false
    var statsModalViewController: StatsModalViewController?
    
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
    
    var altitude10: Double = .nan
    var distance10: Double = .nan
    var denivele10: Double = .nan
    var position10: Double = .nan
    var positionPrecedente10: Double = .nan
    var points: [CLLocation] = []
    
    var timerPenteOpenTopoData: Timer?
    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }
    
    @IBAction func changeUnite() {
        unite = (unite + 1) % facteurUnitesAltitude.count
        userDefaults.set(unite, forKey: keyUnite)
        affichageUnite.setTitle(textesUnites[unite], for: .normal) // = textesUnites[unite]
        if (affichageVitesse.text != "" && locationPrecedente != nil) {
            afficherVitesse(vitesse: locationPrecedente!.speed * facteurUnitesVitesses[unite], precisionOK: true, pente: .nan)
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
    
    @objc func enregistrerStats(){
        userDefaults.set(stats.distanceTotale, forKey: keyDistanceTotale)        
        userDefaults.set(stats.vitesseMax, forKey: keyVitesseMax)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        print("segue identifier " + (segue.identifier ?? "nil"))
        if segue.identifier == nomSegueOuvreStats {
            statsModalViewController = segue.destination as? StatsModalViewController
            guard statsModalViewController != nil else {
                return
            }
            statsModalViewController!.autoriserAffichageTeteHaute = autoriserAffichageTeteHaute
            statsModalViewController!.userDefaults = userDefaults
            statsModalViewController!.locationToujoursAutorisee = locationToujoursAutorisee
            statsModalViewController!.demoMode = demoMode
            statsModalViewController!.delegate = self
        }
    }
    
    @IBAction func ouvrirStats(){
        ouvreStats()
    }
    
    @objc func ouvreStats() {
        //        print("perform segue")
        effaceStatsSiTropVieilles()
        performSegue(withIdentifier: nomSegueOuvreStats, sender: self)
    }
    
    @objc func changeDebugMode() {
        debugMode = !debugMode
        DispatchQueue.main.async{
            self.messageDebug.isHidden = !self.debugMode
            self.labelPente.isHidden = !self.debugMode
        }
    }
    
    @objc func penteOpenTopoData() {
        guard debugMode && locationPrecedente != nil else {
//            DispatchQueue.main.async {
//                self.messageDebug.text = "conditions pas ok"
//            }
            return
        }
        Task {
            let (pente, texte) = await locationPrecedente!.penteDeOpenTopoData()
            DispatchQueue.main.async {
                self.messageDebug.text = String(format: "➚ %.1f%%", pente * 100.0)
            }
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
        debugMode = debugMode && autoriseDebug
        self.roueAttente.style = .large
        self.boutonReactiveChevron.setTitle("", for: .normal)
        self.messagePublic.text = ""
        self.messageDebug.isHidden = !self.debugMode
        self.labelPente.isHidden = !self.debugMode
        self.labelPente.text = ""
        self.labelPente.font = UIFont.monospacedDigitSystemFont(ofSize: self.labelPente.font.pointSize, weight: .regular)
        self.messageDebug.font = UIFont.monospacedDigitSystemFont(ofSize: self.messageDebug.font.pointSize, weight: .regular)
        self.affichageVitesse.text = ""
        self.adapterTailleAffichageVitesse()
        self.unite = self.userDefaults.value(forKey: keyUnite) as? Int ?? 1
        self.affichageUnite.setTitle(textesUnites[self.unite], for: .normal)
        self.stats.vitesseMax = self.userDefaults.value(forKey: keyVitesseMax) as? Double ?? 0.0
        self.stats.distanceTotale = self.userDefaults.value(forKey: keyDistanceTotale) as? Double ?? 0.0
        self.imagePasLocalisation.isHidden = true
        if UITraitCollection.current.accessibilityContrast == .high {
            self.affichageUnite.tintColor = .white
            self.affichageVitesse.textColor = .white
            self.imagePasLocalisation.tintColor = .white
        }

        self.roueAttente.startAnimating()
        
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
        NotificationCenter.default.addObserver(self, selector: #selector(enregistrerStats), name: Notification.Name(keyEnregistrerStats), object: nil)

        boutonOuvreStats.setTitle("", for: .normal)
        if #available(iOS 13.0, *) {
            boutonOuvreStats.setImage(UIImage(systemName: "chevron.compact.up", withConfiguration: UIImage.SymbolConfiguration(pointSize: 48)), for: .normal)
        } else {
            // Fallback on earlier versions
            boutonOuvreStats.setImage(UIImage(named: "chevron.compact.up"), for: .normal)
        }
// par défaut on désactive le mode miroir au premier lancement.
        self.autoriserAffichageTeteHaute = self.userDefaults.value(forKey: keyAutoriserAffichageTeteHaute) as? Bool ?? false
        
        montrerAlerteDemarrage = userDefaults.value(forKey: keyMontrerAlerteDemarrage) as? Bool ?? montrerAlerteDemarrage
        if montrerAlerteDemarrage {
            let alert = UIAlertController(title: NSLocalizedString("Pour votre sécurité", comment: "Titre alerte"), message: NSLocalizedString("avant de conduire, assurez-vous que le mode Avion ou \"Ne pas déranger en voiture\" est activé", comment: "Contenu de l'alerte de sécurité"), preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: NSLocalizedString("Ne plus afficher", comment: ""), style: .default, handler: {_ in self.montrerAlerteDemarrage = false
                self.userDefaults.set(self.montrerAlerteDemarrage, forKey: keyMontrerAlerteDemarrage)
            }))
            alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "bouton OK"), style: .default, handler: {_ in self.gereDroitsLocalisation(origineViewDidLoad: true, origineViewDidAppear: false)}))
            DispatchQueue.main.async{
                self.present(alert, animated: true)
                
                //            self.gabaritAffichageVitesse.isHidden = false
                //            self.gabaritAffichageVitesse.text = String(format:"\u{2007}%d",5)
            }
        }
        scheduledTimerWithTimeInterval()
//        timerPenteOpenTopoData = Timer.scheduledTimer(timeInterval: 5.0, target: self, selector: #selector(self.penteOpenTopo), userInfo: nil, repeats: true)
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
            stats.effacerSession()
            if statsModalViewController != nil {
                statsModalViewController?.afficherStats()
            }
            locationPrecedente = nil
//            altitudePrecedente8 = .nan
            altitudePrecedente10 = .nan
//            altitudePrecedente15 = .nan
            timeStampDernierePosition = 0.0
        }
    }
    
    @objc func verifieQueLocalisationEstActive() {
        effaceStatsSiTropVieilles()
        
        if ((Date().timeIntervalSince1970 -  timeStampDernierePosition)  > tempsMaxEntrePositions) {
            localisationEstPerdue = true
            DispatchQueue.main.async{
                if self.demoMode{
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
    
    
    func gereOrientation(motion: CMDeviceMotion?, error: Error?) {
        let tangage = motion!.attitude.pitch * radiansEnDegres  // basculement vers l'avant
        let roulis = motion!.attitude.roll * radiansEnDegres    // basculement vers le côté
        let commencerPositionTeteHaute = (abs(roulis) < inclinaisonMax) && (abs(roulis) > abs(tangage)) && (UIWindow.isLandscape) && autoriserAffichageTeteHaute // UIDevice.current.orientation.isLandscape est l'orientation physique de l'appareil, quand on est plus ou moins à plat il dit "à plat"
        let arreterPositionTeteHaute = (abs(roulis) > inclinaisonMax + 5.0) || (abs(roulis + 5.0) < abs(tangage)) || !autoriserAffichageTeteHaute
        if commencerPositionTeteHaute {
            positionTeteHaute = true
        } else if arreterPositionTeteHaute {
            positionTeteHaute = false
        }
        self.changerTeteHauteSiNecessaire()
    }

    func changerTeteHauteSiNecessaire() {
        DispatchQueue.main.async{
            if (self.positionTeteHaute != self.anciennePositionTeteHaute) {
                self.affichageVitesse.flipX()
                self.affichageUnite.flipX()
                switch self.affichageUnite.contentHorizontalAlignment {
                case .left: self.affichageUnite.contentHorizontalAlignment = .right
                case .right: self.affichageUnite.contentHorizontalAlignment = .left
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
                if !luminositeEstForcee && self.statsModalViewController == nil && UIApplication.shared.applicationState == .active { //isUserInteractionEnabled { // && self.view.isFirstResponder)
                    luminositeEcranSysteme = UIScreen.main.brightness   // on note la luminosité de l'écran, pour pouvoir y revenir plus tard
                    UIScreen.main.brightness = CGFloat(1.0)  // on met le contraste au max
                    self.messageDebug.textColor = .yellow
                    luminositeEstForcee = true
                }
            }  // téléphone à plat -> position tête haute
            else { // le téléphone est penché -> on affiche le texte en gris pour lecture directe
                if luminositeEstForcee && UIApplication.shared.applicationState == .active { // on revient au contraste par défaut du système
                    stoppeLuminositeMax()
                }
                self.affichageVitesse.textColor = UIScreen.main.brightness >= self.luminositeMinimalePourForcerAffichageBlanc || UITraitCollection.current.accessibilityContrast == .high ? .white : .lightGray
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
        print("droits de localisation : ", CLLocationManager.authorizationStatus().toText())
        locationManager.delegate = self
                self.locationManager.requestAlwaysAuthorization()
                let statut = CLLocationManager.authorizationStatus()
                switch statut {
                case .authorizedAlways, .authorizedWhenInUse:  // l'app a l'autorisation d'accéder à la localisation
                    self.locationToujoursAutorisee = statut == .authorizedAlways
                    self.locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
                    if statut == .authorizedAlways {
                        self.locationManager.allowsBackgroundLocationUpdates = true
                        self.locationManager.pausesLocationUpdatesAutomatically = true // après un certain temps sans bouger, il arrête les mises à jour de la localisation en tâche de fond.
                        self.locationManager.activityType = .otherNavigation
                        if #available(iOS 11.0, *) {
                            self.locationManager.showsBackgroundLocationIndicator = true
                        }
                    }
                    self.locationManager.startUpdatingLocation()
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
                    self.locationToujoursAutorisee = false
                    DispatchQueue.main.async{
                        self.affichageVitesse.text = ""
                        self.affichePictoPasLocalisation()
                    }
                    DispatchQueue.global(qos: .default).async {
                        if (CLLocationManager.locationServicesEnabled()) { // la localisation est activée sur l'appareil
                            print("acces localisation pas ok pour l'app")
                            Task{
                                let leMessage = NSLocalizedString("Pour afficher la vitesse, autorisez l'app à accéder à la localisation \nNB: l'app ne stocke pas votre position ; elle ne la transmet à personne", comment: "Si l'app n'est pas autorisée à accéder à la localisation")
                                await self.afficherAlerteRenvoiPreferences(titre: NSLocalizedString("Autorisez la localisation", comment: "Titre de l'alerte"), message: leMessage, perfsDeLApp: true)
                            }
                        } else {
                            Task{
                                let leMessage = NSLocalizedString("Pour afficher la vitesse, activez la localisation sur votre appareil \nNB: l'app ne stocke pas votre position ; elle ne la transmet à personne", comment: "Si l'appareil n'est pas autorisé à lire la position")
                                await self.afficherAlerteRenvoiPreferences(titre: NSLocalizedString("Autorisez la localisation", comment: "Titre de l'alerte"), message: leMessage, perfsDeLApp: false)
                            }
                        }
                    }
                case .notDetermined:
                    print("not determined")
                    self.locationToujoursAutorisee = false
                default:
                    print("défaut")
                    self.locationToujoursAutorisee = false
                } // switch
//            }    if (CLLocationManager.locationServicesEnabled())
//            else {
//                print("acces localisation pas ok pour le téléphone")
//                self.locationToujoursAutorisee = false
//                DispatchQueue.main.async{
//                    let leMessage = NSLocalizedString("Pour afficher la vitesse, activez la localisation sur votre appareil \nNB: l'app ne stocke pas votre position ; elle ne la transmet à personne", comment: "Si l'appareil n'est pas autorisé à lire la position")
//                    self.afficherAlerteRenvoiPreferences(titre: NSLocalizedString("Autorisez la localisation", comment: "Titre de l'alerte"), message: leMessage, perfsDeLApp: false)
//                    self.affichageVitesse.text = ""
//                    self.affichePictoPasLocalisation()
//                }
//            }
    }
    
    
    func afficherVitesse(vitesse: Double, precisionOK: Bool, pente: Double) {
        DispatchQueue.main.async{
            if (vitesse >= 0 || precisionOK) {
                self.messagePublic.text = ""
                self.imagePasLocalisation.isHidden = true
                self.roueAttente.stopAnimating()  //isHidden = true
                if Int(vitesse) <= 9 {
                    self.affichageVitesse.text = String(format:"\u{2007}%d", Int(vitesse))  // \u{2007} = blanc de même largeur qu'un chiffre
                }
                else {
                    self.affichageVitesse.text = String(format:"%d", Int(vitesse))
                }
//                if !self.debugMode && (pente.isNaN || abs(pente) < penteMinimalePourAffichage || abs(pente) > penteMaximaleCredible) {
//                    self.labelPente.text = ""
//                } else {
//                    let flechePente = pente > 0 ? "➚" : "➘"
//                    self.labelPente.text = String(format: flechePente + " %2.0f%%", abs(pente) * 100.0).replacingOccurrences(of: " ", with: "\u{2007}")
//                }
                self.localisationEstPerdue = false
                self.nombrePasOK = 0
            }  // Vitesse >= 0 et precisionOK
            else {
                if (self.nombrePasOK >= 1) {
                    self.affichageVitesse.text = ""
                    self.affichePictoPasLocalisation()
                    print("pas de signal")
                }
                self.nombrePasOK = self.nombrePasOK + 1
            }
        }
    }
    
    
    //    CLLocationManagerDelegate
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location: CLLocation = locations.last else {return}
        if location.horizontalAccuracy <= precisionHorizontaleMinimalePourAltitudeOpenTopo {
            points.append(location)
        }
        if points.count > pointsPourPente {
            points.removeFirst(points.count - pointsPourPente)
        }
        nombrePositionsLues = nombrePositionsLues + 1
        // au-delà de 12 heures en arrière-plan, on réinitialise le trajet
        if (location.timestamp.timeIntervalSince1970 - timeStampDernierePosition) > tempsAvantReinitialisationAuto {
            stats.effacerSession()
            if statsModalViewController != nil {
                statsModalViewController?.afficherStats()
            }
        }
        let directionOK = location.course >= 0 || (location.speed >= 0 && location.speed < 1)
        let pasTunnelLong = location.timestamp.timeIntervalSince1970 - timeStampDernierePosition < dureeMaxiTunnel
        let localisationsNombreusesOuPrecises = nombrePositionsLues >= nbPositionsMiniAuDemarrage || location.horizontalAccuracy <= 10
        let deplacementDepuisDernierePosition = locationPrecedente?.distance(from: location) ?? 0.0
        let deplacementSelonVitesse = location.speed * location.timestamp.timeIntervalSince(locationPrecedente?.timestamp ?? Date(timeIntervalSince1970: 0))
        let ratioDeplacements = deplacementSelonVitesse / deplacementDepuisDernierePosition
        let deplacementVraisemblable = ratioDeplacements > 0.67 || ratioDeplacements < 1.5
        let vitesseOKPourAffichage = directionOK && pasTunnelLong && localisationsNombreusesOuPrecises && location.courseAccuracy >= 0 && location.speedAccuracy >= 0
        let vitesseOKPourStats = vitesseOKPourAffichage && deplacementVraisemblable
        
//        laVitesseLue = (laVitesseLue >= 0 && location.speedAccuracy > 0) ? laVitesseLue : 0.0
        if vitesseOKPourStats && location.speed > vitesseMiniPourActiverCompteur && timeStampDernierePosition > 0.0 {
            stats.distanceTotale = stats.distanceTotale + deplacementDepuisDernierePosition
            stats.distanceTotaleSession = stats.distanceTotaleSession + deplacementDepuisDernierePosition
            stats.distanceTotale = max(stats.distanceTotale, stats.distanceTotaleSession)
            stats.tempsSession = stats.tempsSession + location.timestamp.timeIntervalSince1970 - timeStampDernierePosition
            if location.speed > stats.vitesseMax {
                stats.vitesseMax = location.speed
            }
            if location.speed > stats.vitesseMaxSession {
                stats.vitesseMaxSession = location.speed
            }
        } // if vitesseOK
        var denivele: Double = .nan
        var pente: Double = .nan
        var nombrePointsOK: Bool = false
        var deltah: Double = .nan
        var d: Double = .nan
        if location.verticalAccuracy <= precisionVerticaleMinimale && location.verticalAccuracy >= 0.0 && !location.altitude.isNaN {

            altitude10 = stats.moyenneGlissanteAltitude10.actualiser(location.altitude)
            denivele10 = stats.moyenneGlissanteDenivele10.actualiser(location.altitude - altitudePrecedente)
            position10 = stats.moyenneGlissantePosition10.actualiser(stats.distanceTotaleSession)
            
            d = position10 - positionPrecedente10
            deltah = altitude10 - altitudePrecedente10
            pente = deltah / d
            
            if vitesseOKPourStats {
                denivele = altitude10 - altitudePrecedente10
                // changer pour utiliser un autre moyennage
                nombrePointsOK = stats.moyenneGlissanteAltitude10.valeurStable()
                if abs(pente) <= penteMaximaleCredible && nombrePointsOK {
                    if denivele >= 0 {
                        stats.denivelePositifSession = stats.denivelePositifSession + denivele
                    } else {
                        stats.deniveleNegatifSession = stats.deniveleNegatifSession - denivele
                    }
                }
                altitudePrecedente10 = altitude10.isNaN ? altitudePrecedente10 : altitude10
                altitudePrecedente = location.altitude.isNaN ? altitudePrecedente : location.altitude
                positionPrecedente10 = position10.isNaN ? positionPrecedente10 : position10
                
            } // if vitesseOK
        }
        afficherVitesse(vitesse: location.speed * facteurUnitesVitesses[unite], precisionOK: vitesseOKPourAffichage, pente: pente)
        if statsModalViewController != nil {
            statsModalViewController?.afficherStats()
        }
        if location.speed > vitesseMiniPourCacherChevron && Date().timeIntervalSince(dateDernierBoutonReactiveChevron) > tempsMiniAffichageChevron && !boutonOuvreStats.isHidden {
            DispatchQueue.main.async {
                self.boutonOuvreStats.isHidden = true
            }
        } else if location.speed < 0.2 && boutonOuvreStats.isHidden {  //  && vitesseOKPourAffichage
            DispatchQueue.main.async {
                self.boutonOuvreStats.isHidden = false
            }
        }
//        NotificationCenter.default.post(name: NSNotification.Name(rawValue: notificationMiseAJourStats), object: nil)
//        let affichageSecret = String(format:"<d> %.1f, ∆h %.2f, ➚ %.1f%%\nd %.1f, h %.2f, <h> %.2f", d, deltah,  pente * 100.0, deplacementDepuisDernierePosition, location.altitude, altitude10)
        locationPrecedente = location
        timeStampDernierePosition = location.timestamp.timeIntervalSince1970
//        DispatchQueue.main.async{
//            self.messageDebug.text = affichageSecret
//        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        localisationEstPerdue = true
//            if CLLocationManager.locationServicesEnabled() { // la localisation est activée sur l'appareil
                if CLLocationManager.authorizationStatus() != .denied && CLLocationManager.authorizationStatus() != .restricted {
                    DispatchQueue.main.async{
                        //            self.messageSecret.isHidden = false
                        self.messagePublic.text = NSLocalizedString("Erreur de localisation", comment: "Erreur de localisation")
                        self.affichageVitesse.text = ""
                        self.affichePictoPasLocalisation()
                        //            self.imagePasLocalisation.isHidden = false
                    }
                }
//            }
            print(error)
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        gereDroitsLocalisation(origineViewDidLoad: false, origineViewDidAppear: false)
    }
    
    func regressionLineaire(x: [Double], y: [Double]) -> (Double, Double, Double, Double) {
        let longueur = x.count
        if longueur == 0 {
            return (.nan, .nan, .nan, .nan)
        }
        if x.count == 1 && y.count == 1  {
            return (.nan, .nan, y.first!, y.first!)
        }
        /// renvoie la pente, l'ordonnée à l'origine et l'ordonnée à la fin
        guard longueur == y.count && longueur >= 2 else {
            return (.nan, .nan, .nan, .nan)
        }
        let xMoyen = x.reduce(0.0, +) / Double(longueur) //Double(x.count)
        let yMoyen = y.reduce(0.0, +) / Double(longueur) // Double(y.count)
        let xReduit = x.map({$0 - xMoyen})
        let yReduit = y.map({$0 - yMoyen})
        let xxReduit = xReduit.map({pow($0, 2.0)})
        let yyReduit = yReduit.map({pow($0, 2.0)})
//            let yyReduit = y.map({pow($0, 2.0)})
        var xyReduit = Array(repeating: 0.0, count: longueur)
        for i in 0...longueur - 1 {
            xyReduit[i] = xReduit[i] * yReduit[i]
        }
        let a = xyReduit.reduce(0.0, {$0 + $1})
        let b = xxReduit.reduce(0.0, {$0 + $1})
//            let ecartTypeXCarre = b / Double(longueur - 1)
//            let ecartTypeYCarre = yyReduit.reduce(0.0, {$0 + $1}) / Double(longueur - 1)
        let pente = a / b
        let ecartTypeXCarre = b / Double(longueur - 1)
        let ecartTypeYCarre = yyReduit.reduce(0.0, {$0 + $1}) / Double(longueur - 1)
        let ecartTypePente = sqrt((ecartTypeYCarre / ecartTypeXCarre - pow(pente, 2.0)) / Double(longueur - 2))  // Méthodes statistiques médecine-biologie statistique, p 191 et suivantes
        let ordonneeALOrigine = pente.isNaN || pente.isInfinite ? yMoyen : yMoyen - pente * xMoyen
//        let ordonneeALaFin = pente.isNaN || pente.isInfinite ? yMoyen : ordonneeALOrigine + pente * x.last!
        let ordonneeAuMilieu = pente.isNaN || pente.isInfinite ? yMoyen : ordonneeALOrigine + pente * ((x.last! + x.first!) / 2.0)
            return(pente, ecartTypePente, ordonneeALOrigine, ordonneeAuMilieu)
    }
    
    override func didReceiveMemoryWarning() {
        enregistrerStats()
    }
    
    func statsModalViewControllerDidTapEffacerSession(_ viewController: StatsModalViewController) {
        stats.effacerSession()
    }
    
    func statsModalViewControllerDidTapEffacerTotal(_ viewController: StatsModalViewController) {
        stats.effacerTout()
    }
    
    func actualiserAffichageTeteHaute(autoriserAffichageTeteHaute: Bool) {
        self.autoriserAffichageTeteHaute = autoriserAffichageTeteHaute
    }

    func texteAffichageValeur(prefixe: String, format: String, valeur: Double, unite: String) -> String {
        return prefixe + String(format: format, valeur).replacingOccurrences(of: " ", with: "\u{2007}") + " " + unite  // .replacingOccurrences(of: " ", with: "\u{2007}")
    }
    
    func afficherStatsReelles(_ viewController: StatsModalViewController) {
        let formatVitesseMax = self.stats.vitesseMax >= 100.0 ? "%3.0f" : "%5.1f"
        viewController.labelVitesseMax.text = texteAffichageValeur(prefixe: "Max ", format: formatVitesseMax, valeur: self.stats.vitesseMax * facteurUnitesVitesses[self.unite], unite: textesUnites[self.unite])
        let formatVitesseMaxSession = self.stats.vitesseMaxSession >= 100.0 ? "%3.0f" : "%5.1f"
        viewController.labelVitesseMaxSession.text = texteAffichageValeur(prefixe: "Max ", format: formatVitesseMaxSession, valeur: self.stats.vitesseMaxSession * facteurUnitesVitesses[self.unite], unite: textesUnites[self.unite])
        viewController.labelDistanceTotale.text = texteAffichageValeur(prefixe: "", format: "%.1f", valeur: self.stats.distanceTotale * facteurUnitesDistance[self.unite], unite: textesUnitesDistance[self.unite])
        let formatDistanceTotaleSession = debugMode ? "%.3f" : "%.1f"
            viewController.labelDistanceTotaleSession.text = texteAffichageValeur(prefixe: "", format: formatDistanceTotaleSession, valeur: self.stats.distanceTotaleSession * facteurUnitesDistance[self.unite], unite: textesUnitesDistance[self.unite])
        let separateur = self.view.frame.width > self.view.frame.height ? ", " : "\n"
        
        viewController.labelDeniveleSession.text = texteAffichageValeur(prefixe: "➚ ", format: "%4.0f", valeur: self.stats.denivelePositifSession * facteurUnitesAltitude[self.unite], unite: textesUnitesAltitude[self.unite]) + separateur + texteAffichageValeur(prefixe: "➘ ", format: "%4.0f", valeur: self.stats.deniveleNegatifSession * facteurUnitesAltitude[self.unite], unite: textesUnitesAltitude[self.unite])
        let secondes = Int(self.stats.tempsSession) % 60
        let minutesTot = Int(self.stats.tempsSession) / 60
        let minutes = minutesTot % 60
        let heures = minutesTot / 60
        var message = heures > 0 ? String(format:NSLocalizedString("Trajet (%d h %02d min", comment: ""), heures, minutes) : String(format:NSLocalizedString("Trajet (%02d min", comment: ""), minutes)
        if self.debugMode {
            message = message.appending(String(format:" %02d s", secondes))
        }
        message = message + ")"
        viewController.labelTitreTrajetEnCours.text = message
        let vitesseMoyenne = self.stats.distanceTotaleSession / self.stats.tempsSession
        if vitesseMoyenne.isFinite && self.stats.tempsSession >= 10.0 && vitesseMoyenne < self.stats.vitesseMaxSession {
            let formatVitesseMoyenne = vitesseMoyenne >= 100.0 ? "%3.0f" : "%5.1f"

            viewController.labelVitesseMoyenne.text = texteAffichageValeur(prefixe: NSLocalizedString("Moyenne ", comment: ""), format: formatVitesseMoyenne, valeur: vitesseMoyenne * facteurUnitesVitesses[self.unite], unite: textesUnites[self.unite])
        } else {
            viewController.labelVitesseMoyenne.text = "" //NSLocalizedString("Moyenne ", comment: "") + " ---  "// + textesUnites[self.unite]
        }
        viewController.boutonUnite.setTitle(textesUnites[self.unite], for: .normal)
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        changerTeteHauteSiNecessaire()
    }
    
//    func statsModalViewControllerDidTapOK(_ viewController: StatsModalViewController) {
//        stats = viewController.stats
//    }
      
    
    @objc func penteOpenTopo() {
        guard debugMode && UIApplication.shared.applicationState == .active else {
            print("penteOpenTopo background")
            return
        }
        guard points.count >= 2 else {
            DispatchQueue.main.async {
                self.messageDebug.text = String(format: "penteOpenTopo %d points", self.points.count)
            }
            return
        }
        Task {
            var distanceTot = 0.0
            var texteURL = "https://api.opentopodata.org/v1/eudem25m?locations="
            var pointPrecedent: CLLocation = points.first!
            var distancesCumulees: [Double] = []
            for point in points {
                distanceTot = distanceTot + point.distance(from: pointPrecedent)
                distancesCumulees.append(distanceTot)
                texteURL.append(String(format: "%f,%f%%7C", point.coordinate.latitude, point.coordinate.longitude))
                pointPrecedent = point
            }
            let precisionHorizontale = points.map({$0.horizontalAccuracy}).max() ?? .infinity
            let precisionRelativeDeplacemnt = precisionHorizontale / distanceTot
            var texteDebug = ""
//            for distancesCumulee in distancesCumulees {
//                texteDebug.append(String(format: "%.0f, ", distancesCumulee))
//            }
            texteDebug.append(String(format: "d %.1f m ", distanceTot))
//            print("distances cumulées", distancesCumulees)
            guard distanceTot > 10.0 && distanceTot < 500.0 else {
                DispatchQueue.main.async {
                    self.messageDebug.text = texteDebug + String(format: "penteOpenTopo distance %.1f", distanceTot)
                    self.messageDebug.textColor = .systemRed
                }
                return
            }
            print("url", texteURL)
            if let urlDEM = URL(string: texteURL) {
                do {
                    let (data, _) = try await URLSession.shared.data(from: urlDEM)
                    let texte = String(data: data, encoding: .utf8) ?? ""
                    print("texte réponse", texte)
                    let statutOK = texte.contains("\"status\": \"OK\"")
                    if statutOK {
                        let elements = texte.components(separatedBy: "\"elevation\": ").dropFirst(1)
                        guard elements.count >= 2 else {
                            print("Pas assez d'éléments")
                            DispatchQueue.main.async {
                                self.messageDebug.text = texteDebug + String(format: "penteOpenTopo %d d'altitudes", elements.count)
                                self.messageDebug.textColor = .systemRed
                            }
                            return
                        }
                        var altitudes: [Double] = []
                        for element in elements {
                            let nombre = element.components(separatedBy: ",").first ?? ""
                            let altitude = Double(nombre) ?? .nan
                            altitudes.append(altitude)
                        }
                        print("altitudes", altitudes)
                        let (pente, ecartTypePente, _, _) = regressionLineaire(x: distancesCumulees, y: altitudes)
                        print("pente", pente, " ± ", ecartTypePente)
                        let deltaAltitude = abs((altitudes.max() ?? .infinity) - (altitudes.min() ?? -.infinity))
                        let incertitudeRelative = ecartTypePente / abs(pente) + 0.1 / deltaAltitude + precisionRelativeDeplacemnt
                        texteDebug.append(String(format: "∆x %.0f%%, ∆h %.0f%%, ∆➚ %.0f%%, ∆ %.0f%%, ", precisionRelativeDeplacemnt * 100.0, 0.1 / deltaAltitude * 100.0, ecartTypePente / abs(pente) * 100.0, incertitudeRelative * 100.0))
//                        texteDebug.append("\n")
//                        for altitude in altitudes {
//                            texteDebug.append(String(format: "%.1f, ", altitude))
//                        }
                        let penteOK = abs(pente) > 0.02 && incertitudeRelative < 0.25
                        DispatchQueue.main.async {
                            self.messageDebug.text = texteDebug + String(format: "➚ %.1f ± %.1f%%", pente * 100.0, abs(pente) * incertitudeRelative * 100.0)
                            self.messageDebug.textColor = penteOK ? .systemGreen : .systemOrange
                            if penteOK {
                                let flechePente = pente > 0 ? "➚" : "➘"
                                self.labelPente.text = String(format: flechePente + " %2.0f%%", abs(pente) * 100.0).replacingOccurrences(of: " ", with: "\u{2007}")
                            } else {
                                self.labelPente.text = ""
                            }
                        }
                        return
                    } else {
                        print("statut pas ok")
                        DispatchQueue.main.async {
                            self.messageDebug.text = texteDebug + String("penteOpenTopo Statut pas ok")
                            self.messageDebug.textColor = .systemRed
                        }
                        return
                    }
                } catch {
                    print("Erreur de lecture de l'altitude")
                    DispatchQueue.main.async {
                        self.messageDebug.text = String("penteOpenTopo Erreur lecture altitude")
                        self.messageDebug.textColor = .systemRed
                    }
                    return
                }
                
            } else {
                print("penteOpenTopo autres")
                DispatchQueue.main.async {
                    self.messageDebug.text = String("penteOpenTopo autres")
                    self.messageDebug.textColor = .systemRed
                }
                return
            }
        }
    }
    
}






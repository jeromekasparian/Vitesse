//
//  ViewController.swift
//  Vitesse
//
//  Created by Jérôme Kasparian on 25/04/2021.
//

/// feuille de route
// la statusbar ne se cache pas sous ios 14.5 ??
// localisation FR
// localisation EN
// Localisation DE
// autres localisations ?
// icone non SF
// Nom de l'app

// Amortir l'affichage au début si l'incertitude sur la localisation est trop grande (utiliser courseaccuracy?)

// après validation d'Hervé :
// - supprimer l'image localisation perdue

import UIKit
import CoreLocation
import CoreMotion

let autoriseDebug = true
var debugMode: Bool = false

let keyUnite = "uniteAuDemarrage"
let keyVitesseMax = "vitesseMax"
let keyDistanceTotale = "distanceTotale"
let notificationMiseAJourStats = "miseAJourStats"
var vitesseMax = 0.0
var vitesseMaxSession = 0.0
var distanceTotale = 0.0
var distanceTotaleSession = 0.0
var unite: Int = 1 // par défaut, km/h
let textesUnites: [String] = [NSLocalizedString("m/s", comment: "vistesse : m/s"),NSLocalizedString("km/h", comment: "vitesse : km/h"),NSLocalizedString("mph", comment: "vitesse : mph")]
let facteurUnites: [Double] = [1.0, 3.6, 2.2369362920544]
let textesUnitesDistance: [String] = [NSLocalizedString("km", comment: "distance : km"),NSLocalizedString("km", comment: "distance : km"),NSLocalizedString("mi", comment: "distance : mi")]
let facteurUnitesDistance: [Double] = [1.0, 0.001, 0.00062137]

class ViewController: UIViewController, CLLocationManagerDelegate {
    
    let userDefaults = UserDefaults.standard
    var locationManager: CLLocationManager! = CLLocationManager()
    let inclinaisonMax = 38.0 // inclinaison max en degres
    let radiansEnDegres = 180.0 / 3.14
    var anciennePositionDressee : Bool = true
    var nouveauDresse : Bool = true
    var locationPrecedente: CLLocation! = nil
//    var justLoaded : Bool = true
    
    
    //    var imagePasDeVitesse = NSTextAttachment()
    //    var messagePasDeVitesse = NSMutableAttributedString(string: "Attente localisation")
    
    let motionManager = CMMotionManager()
    
    @IBOutlet weak var affichageVitesse: UILabel!
    @IBOutlet var affichageUnite: UIButton!
    @IBOutlet var imageLocalisation: UIImageView!
    @IBOutlet var imagePasLocalisation: UIImageView!
    @IBOutlet var imageLocalisationPerdue: UIImageView!
    @IBOutlet var roueAttente: UIActivityIndicatorView!
    @IBOutlet var messageSecret: UILabel!  // caché dans l'interface - utile pour les tests de début
//    @IBOutlet var swipeRegion: UISwipeGestureRecognizer!
    
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
        messageSecret.isHidden = !debugMode
    }

    
    override func viewDidLoad() {
//        justLoaded = true
        debugMode = debugMode && autoriseDebug
        messageSecret.isHidden = !debugMode
        unite = userDefaults.value(forKey: keyUnite) as? Int ?? 1
        vitesseMax = userDefaults.value(forKey: keyVitesseMax) as? Double ?? 0.0
        distanceTotale = userDefaults.value(forKey: keyDistanceTotale) as? Double ?? 0.0

        // mise en place de la détection du swipe up pour ouvrir le tiroir des stats
        let swipeHaut = UISwipeGestureRecognizer(target:self, action: #selector(ouvreStats))
        swipeHaut.direction = UISwipeGestureRecognizer.Direction.up
        self.view.addGestureRecognizer(swipeHaut)

        let swipeDebug = UISwipeGestureRecognizer(target:self, action: #selector(changeDebugMode))
        swipeDebug.direction = UISwipeGestureRecognizer.Direction.left
        swipeDebug.numberOfTouchesRequired = 3
        self.view.addGestureRecognizer(swipeDebug)
        
//        locationManager.requestWhenInUseAuthorization()
        gereDroitsLocalisation(origineViewDidLoad: true, origineViewDidAppear: false)
        
        motionManager.deviceMotionUpdateInterval = 1
        // Get attitude orientation
            motionManager.startDeviceMotionUpdates(to: .main, withHandler: gereOrientation) //{ (motion, error) in

        NotificationCenter.default.addObserver(self, selector: #selector(gereDroitsLocationDepuisNotification), name: UIApplication.didBecomeActiveNotification, object: nil)

        UIApplication.shared.isIdleTimerDisabled = true
        
        let alert = UIAlertController(title: NSLocalizedString("Pour votre sécurité", comment: "Titre alerte"), message: NSLocalizedString("activez le mode \"Ne pas déranger\" du téléphone avant de conduire", comment: "Contenu de l'alerte de sécurité"), preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "bouton OK"), style: .default, handler: {_ in print("Alerte NPD validée")}))
        DispatchQueue.main.async{
            self.affichageUnite.setTitle(textesUnites[unite], for: .normal)
            self.present(alert, animated: true)
        }
        super.viewDidLoad()
        print("init ok")
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        userDefaults.set(distanceTotale, forKey: keyDistanceTotale)
        userDefaults.set(vitesseMax, forKey: keyVitesseMax)
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
        nouveauDresse = ((abs(roulis) < abs(tangage)) || (abs(roulis) > inclinaisonMax))
        DispatchQueue.main.async{
            if !(self.nouveauDresse == self.anciennePositionDressee) {
                self.affichageVitesse.flipX()
                self.affichageUnite.flipX()
                self.anciennePositionDressee = self.nouveauDresse
            }
            if self.nouveauDresse { // le téléphone est penché -> on affiche le texte en gris pour lecture directe
                self.affichageVitesse.textColor = .lightGray
                //                print("dressé")
            }
            else {  // le téléphone est à plat -> on affiche le texte en blanc pour réflexion sur le pare-brise
                self.affichageVitesse.textColor = .white
                //                print("à plat")
            }
            self.affichageUnite.setTitle(textesUnites[unite], for: .normal) // = textesUnites[unite]
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
                    self.messageSecret.text = ""
                    self.messageSecret.isHidden = !debugMode
                    self.affichageVitesse.text = ""
                    self.imageLocalisation.isHidden = false
                    self.imagePasLocalisation.isHidden = true
//                    self.imageLocalisationPerdue.isHidden = true
                    self.roueAttente.stopAnimating()  //isHidden = true
                }
            case .denied, .restricted:
                print("acces localisation pas ok pour l'app")
                DispatchQueue.main.async{
                    self.messageSecret.text = NSLocalizedString("Pour afficher la vitesse, autorisez l'app à accéder à la localisation : \nRéglages -> Condidentialité -> Service de localisation \nNB: l'app ne stocke pas votre position ; elle ne la transmet à personne", comment: "Si l'app n'est pas autorisée à accéder à la localisation")
                    self.messageSecret.isHidden = false
                    self.affichageVitesse.text = ""
                    self.imageLocalisation.isHidden = true
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
                self.messageSecret.text = NSLocalizedString("Pour afficher la vitesse, activez la localisation sur votre appareil : \nRéglages -> Condidentialité -> Service de localisation \nNB: l'app ne stocke pas votre position ; elle ne la transmet à personne", comment: "Si l'appareil n'est pas autorisé à lire la position")
                self.messageSecret.isHidden = false
                self.affichageVitesse.text = ""
                self.imageLocalisation.isHidden = true
                self.imagePasLocalisation.isHidden = false
//                self.imageLocalisationPerdue.isHidden = true
                self.roueAttente.stopAnimating()  //isHidden = true
            }
        }
    }
    
    
    func afficherVitesse(vitesse: Double, precisionOK: Bool) {
        print("vitesse : \(vitesse) \(textesUnites[unite])")
        DispatchQueue.main.async{
            self.imageLocalisation.isHidden = true
            self.imagePasLocalisation.isHidden = true
            if ((vitesse >= 0) && precisionOK) {
//                self.imageLocalisationPerdue.isHidden = true
                self.roueAttente.stopAnimating()  //isHidden = true
//                self.affichageVitesse.isHidden = false
//                if (vitesse >= 10) {
                    self.affichageVitesse.text = String(format:"%.0f",vitesse)
//                }
//                else { self.affichageVitesse.text = String(format:"%.1f",vitesse) }
            }
            else {
//                self.affichageVitesse.isHidden = false
                self.affichageVitesse.text = ""
//                self.imageLocalisationPerdue.isHidden = false
                self.roueAttente.startAnimating()  //isHidden = false
                print("pas de signal")
            }
            //        print("locations = \(String(describing: locations))")
        }
    }

    //    CLLocationManagerDelegate
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location:CLLocation = locations.last!
        //        print("vitesse : \(location.speed) m/s")

        let vitesse = location.speed * facteurUnites[unite]
        let vitesseOK = (vitesse == 0) || (location.course >= 0)
        var laDistance = -3.33
        if vitesseOK {
            if (location.speed > vitesseMax) {vitesseMax = vitesse}
            if (location.speed > vitesseMaxSession) {vitesseMaxSession = vitesse}
            if !(locationPrecedente == nil) {
                laDistance =  location.distance(from: locationPrecedente)
                distanceTotale = distanceTotale + laDistance
                distanceTotaleSession = distanceTotaleSession + laDistance
            }
            locationPrecedente = location
                NotificationCenter.default.post(name : Notification.Name(notificationMiseAJourStats),object: nil)  // on prévient le ViewController d'actualiser l'affichage et d'enregistrer
        }

        afficherVitesse(vitesse: vitesse, precisionOK: vitesseOK)  // course (= le cap) est -1 la plupart du temps pendant que le système affine la localisaiton lorsqu'il vient d'avoir le droit d'y accéder
        if debugMode{
            let affichageSecret = String(format:"v %.2f ∆v %.1f, Ω %.1f, ∆x %.1f, \nd %.3f, t %.0f", vitesse, location.speedAccuracy, location.course, location.horizontalAccuracy, laDistance, location.timestamp.timeIntervalSince1970)
            messageSecret.text = affichageSecret
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error)
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
//        locationManager.requestWhenInUseAuthorization()
        gereDroitsLocalisation(origineViewDidLoad: false, origineViewDidAppear: false)
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

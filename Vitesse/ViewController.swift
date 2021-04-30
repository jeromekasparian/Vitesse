//
//  ViewController.swift
//  Vitesse
//
//  Created by Jérôme Kasparian on 25/04/2021.
//

/// feuille de route
// Amortir l'affichage au début si l'incertitude sur la localisation est trop grande
// cacher la statusbar
// localisation EN
// Localisation DE
// autres localisations ?
// icone non SF
// se souvenir de l'unité d'une fois sur l'autre
//Rafraîchir l’affichage de la vitesse quand on change l’unité
//Redemander l’autorisation d’accéder à la localisation quand l’app redémarre après une mise en veille
//Mettre un chiffre après la virgule si la vitesse est plus petite que 10

import UIKit
import CoreLocation
import CoreMotion

class ViewController: UIViewController, CLLocationManagerDelegate {
    
    var locationManager: CLLocationManager! = CLLocationManager()
    var unite: Int = 1 // par défaut, km/h
    let textesUnites: [String] = ["m/s","km/h","mph"]
    let facteurUnites: [Double] = [1.0, 3.6, 2.2369362920544]
    let inclinaisonMax = 38.0 // inclinaison max en degres
    let radiansEnDegres = 180.0 / 3.14
    var anciennePositionDressee : Bool = true
    var nouveauDresse : Bool = true
    
    
    //    var imagePasDeVitesse = NSTextAttachment()
    //    var messagePasDeVitesse = NSMutableAttributedString(string: "Attente localisation")
    
    let motionManager = CMMotionManager()
    
    @IBOutlet weak var affichageVitesse: UILabel!
    @IBOutlet var affichageUnite: UIButton!
    @IBOutlet var imageLocalisation: UIImageView!
    @IBOutlet var imagePasLocalisation: UIImageView!
    @IBOutlet var imageLocalisationPerdue: UIImageView!
    
    @IBAction func changeUnite () {
        unite = (unite + 1) % 3
        affichageUnite.setTitle(textesUnites[unite], for: .normal) // = textesUnites[unite]
    }
    
    override func viewDidLoad() {
        locationManager.requestWhenInUseAuthorization()
        gereDroitsLocalisation(origineViewDidLoad: true)
        
        motionManager.deviceMotionUpdateInterval = 1
        // Get attitude orientation
            motionManager.startDeviceMotionUpdates(to: .main, withHandler: gereOrientation) //{ (motion, error) in
//            let tangage = motion!.attitude.pitch * radiansEnDegres  // basculement vers l'avant
//            let roulis = motion!.attitude.roll * radiansEnDegres    // basculement vers le côté
//            let azimutInverse = motion!.attitude.yaw * radiansEnDegres    // Azimut, haut du téléphone vers le sud = 0
//            print(String(format:"orientation : %.2f, %.2f, %.2f", tangage, roulis, azimutInverse))
//            //            nouveauDresse = (abs(roulis) > inclinaisonMax)
//            nouveauDresse = (!(UIDevice.current.orientation.isLandscape) || (abs(roulis) > inclinaisonMax))
//            DispatchQueue.main.async{
//                if !(nouveauDresse == anciennePositionDressee) {
//                    self.affichageVitesse.flipX()
//                    self.affichageUnite.flipX()
//                    anciennePositionDressee = nouveauDresse
//                }
//                if nouveauDresse { // le téléphone est penché -> on affiche le texte en gris pour lecture directe
//                    affichageVitesse.textColor = .lightGray
//                    //                print("dressé")
//                }
//                else {  // le téléphone est à plat -> on affiche le texte en blanc pour réflexion sur le pare-brise
//                    affichageVitesse.textColor = .white
//                    //                print("à plat")
//                }
//                affichageUnite.setTitle(textesUnites[unite], for: .normal) // = textesUnites[unite]
//            } // DispatchQueue.main.async
   //     } //  motionManager.startDeviceMotionUpdates
        
        UIApplication.shared.isIdleTimerDisabled = true
        
        let alert = UIAlertController(title: "Pour votre sécurité", message: "activez le mode \"Ne pas déranger\" du téléphone avant de conduire", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: {_ in print("Alerte NPD validée")}))
        DispatchQueue.main.async{
            self.affichageUnite.setTitle(self.textesUnites[self.unite], for: .normal)
            self.present(alert, animated: true)
        }
        super.viewDidLoad()
        print("init ok")
    }
    
    func gereOrientation(motion:CMDeviceMotion?,error:Error?) {
        let tangage = motion!.attitude.pitch * radiansEnDegres  // basculement vers l'avant
        let roulis = motion!.attitude.roll * radiansEnDegres    // basculement vers le côté
        let azimutInverse = motion!.attitude.yaw * radiansEnDegres    // Azimut, haut du téléphone vers le sud = 0
        print(String(format:"orientation : %.2f, %.2f, %.2f", tangage, roulis, azimutInverse))
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
            self.affichageUnite.setTitle(self.textesUnites[self.unite], for: .normal) // = textesUnites[unite]
        } // DispatchQueue.main.async
    }
    
    
    func gereDroitsLocalisation(origineViewDidLoad : Bool) {
        print("lancement au démarrage : \(origineViewDidLoad)")
        locationManager.delegate = self

        if (CLLocationManager.locationServicesEnabled()) { // la localisation est activée sur l'appareil
            print("droits de localisation : ", CLLocationManager.authorizationStatus().rawValue)

            switch CLLocationManager.authorizationStatus() {
                case .authorizedAlways, .authorizedWhenInUse:  // l'app a l'autorisation d'accéder à la localisation
                locationManager.desiredAccuracy = kCLLocationAccuracyBest
                locationManager.startUpdatingLocation();
                print("acces localisation ok")
                //            self.imagePasDeVitesse.image = UIImage(systemName: "location.fill")
                DispatchQueue.main.async{
                    self.imageLocalisation.isHidden = false
                    self.imagePasLocalisation.isHidden = true
                    self.imageLocalisationPerdue.isHidden = true
                }
            case .denied, .restricted:
                print("acces localisation pas ok pour l'app")
                DispatchQueue.main.async{
                    self.imageLocalisation.isHidden = true
                    self.imagePasLocalisation.isHidden = false
                    self.imageLocalisationPerdue.isHidden = true
                }
            case .notDetermined:
                print("not determined")
            default:
                print("défaut")
            } // switch
        }  //  if (CLLocationManager.locationServicesEnabled())
        else {
            print("acces localisation pas ok pour le téléphone")
            //            print("􀘭")//accès localisation  pas ok")
            DispatchQueue.main.async{
                self.imageLocalisation.isHidden = true
                self.imagePasLocalisation.isHidden = false
                self.imageLocalisationPerdue.isHidden = true
            }
        }
    }
    
    //    CLLocationManagerDelegate
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location:CLLocation = locations.last!
        //        print("vitesse : \(location.speed) m/s")
        let vitesse = location.speed * facteurUnites[unite]
        print("vitesse \(vitesse) km/h")
        DispatchQueue.main.async{
            self.imageLocalisation.isHidden = true
            self.imagePasLocalisation.isHidden = true
            if vitesse >= 0 {
                self.imageLocalisationPerdue.isHidden = true
                self.affichageVitesse.isHidden = false
                self.affichageVitesse.text = String(format:"%.0f",vitesse)
            }
            else {
                self.affichageVitesse.isHidden = false
                self.affichageVitesse.text = ""
                self.imageLocalisationPerdue.isHidden = false
                print("pas de signal")
            }
            //        print("locations = \(String(describing: locations))")
        }
        
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error)
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        gereDroitsLocalisation(origineViewDidLoad: false)
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

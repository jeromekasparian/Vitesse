//
//  ViewController.swift
//  Vitesse
//
//  Created by Jérôme Kasparian on 25/04/2021.
//

/// feuille de route
// afficher km/h
// couleur / contraste
// affichage inversé (selon la position ?)
// do not disturb : alerte

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
    
    let motionManager = CMMotionManager()

    @IBOutlet weak var affichageVitesse: UILabel!
    @IBOutlet weak var affichageUnite: UIButton!
    
    @IBAction func changeUnite () {
        unite = (unite + 1) % 3
        affichageUnite.setTitle(textesUnites[unite], for: .normal) // = textesUnites[unite]
    }
    
    override func viewDidLoad() {
        locationManager.requestWhenInUseAuthorization()
        if (CLLocationManager.locationServicesEnabled())
        {
            print("accès localisation ok")
        locationManager.delegate = self
//        locationManager.distanceFilter = kCLDistanceFilterNone
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.startUpdatingLocation();
        }
        
        motionManager.deviceMotionUpdateInterval = 1
        // Get attitude orientation
        motionManager.startDeviceMotionUpdates(to: .main) { [self] (motion, error) in
            let tangage = motion!.attitude.pitch * radiansEnDegres  // basculement vers l'avant
            let roulis = motion!.attitude.roll * radiansEnDegres    // basculement vers le côté
            let azimutInverse = motion!.attitude.yaw * radiansEnDegres    // Azimut, haut du téléphone vers le sud = 0
            print(String(format:"orientation : %.2f, %.2f, %.2f", tangage, roulis, azimutInverse))
            nouveauDresse = (abs(tangage) > inclinaisonMax) || (abs(roulis) > inclinaisonMax)
            DispatchQueue.main.async{
                if !(nouveauDresse == anciennePositionDressee) {
                    self.affichageVitesse.flipX()
                    self.affichageUnite.flipX()
                    anciennePositionDressee = nouveauDresse
                }
            if nouveauDresse { // le téléphone est penché -> on affiche le texte en gris pour lecture directe
                        affichageVitesse.textColor = .lightGray
//                print("dressé")
            }
            else {  // le téléphone est à plat -> on affiche le texte en blanc pour réflexion sur le pare-brise
                        affichageVitesse.textColor = .white
//                print("à plat")
            }
            } // DispatchQueue.main.async
        } //  motionManager.startDeviceMotionUpdates
        
        UIApplication.shared.isIdleTimerDisabled = true
        
        affichageUnite.setTitle(textesUnites[unite], for: .normal) // = textesUnites[unite]
        let alert = UIAlertController(title: "Pour votre sécurité", message: "activez le mode \"Ne pas déranger\" du téléphone avant de conduire", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: {_ in print("tata")}))
        DispatchQueue.main.async{
            self.present(alert, animated: true)
            self.affichageVitesse.text = "Attente du signal…"
        }
        super.viewDidLoad()
        print("init ok")
    }

    //CLLocationManagerDelegate
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location:CLLocation = locations.last!
//        print("vitesse : \(location.speed) m/s")
        let vitesse = location.speed * facteurUnites[unite]
//        print("vitesse \(vitesse) km/h")
        DispatchQueue.main.async{
            if vitesse >= 0 { self.affichageVitesse.text = String(format:"%.0f",vitesse) }
            else { self.affichageVitesse.text = "Attente du signal…" }
//        print("locations = \(String(describing: locations))")
        }
        
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error)
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

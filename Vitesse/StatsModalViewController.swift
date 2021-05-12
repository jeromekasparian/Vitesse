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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        boutonEffacerSession.setTitle("", for: .normal)
        boutonEffacerSession.setImage(UIImage(systemName: "xmark"), for: .normal)
        afficherStats()
        NotificationCenter.default.addObserver(self, selector: #selector(afficherStats), name: NSNotification.Name(rawValue: notificationMiseAJourStats), object: nil)
        // Do any additional setup after loading the view.
        
        // mise en place de la détection du swipe down pour fermer le tiroir des stats
        let swipeBas = UISwipeGestureRecognizer(target:self, action: #selector(fermerStats))
        swipeBas.direction = UISwipeGestureRecognizer.Direction.down
        self.view.addGestureRecognizer(swipeBas)

    }
    
    @IBAction func fermerStats () {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func effacerSession() {
        vitesseMaxSession = 0.0
        distanceTotaleSession = 0.0
        afficherStats()
    }
    
    @objc func afficherStats(){
        labelVitesseMax.text = String(format: "%.0f ", vitesseMax * facteurUnites[unite])
        labelVitesseMax.text?.append(textesUnites[unite])
        labelVitesseMaxSession.text = String(format: "%.0f ", vitesseMaxSession * facteurUnites[unite])
        labelVitesseMaxSession.text?.append(textesUnites[unite])
        
        if (unite == 0) { labelDistanceTotale.text = String(format: "%.0f ", distanceTotale * facteurUnitesDistance[unite]) }
        else { labelDistanceTotale.text = String(format: "%.1f ", distanceTotale * facteurUnitesDistance[unite]) }
        labelDistanceTotale.text?.append(textesUnitesDistance[unite])
        if (unite == 0) { labelDistanceTotaleSession.text = String(format: "%.0f ", distanceTotaleSession * facteurUnitesDistance[unite]) }
        else { labelDistanceTotaleSession.text = String(format: "%.1f ", distanceTotaleSession * facteurUnitesDistance[unite]) }
        labelDistanceTotaleSession.text?.append(textesUnitesDistance[unite])
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

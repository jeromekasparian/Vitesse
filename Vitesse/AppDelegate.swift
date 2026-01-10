//
//  AppDelegate.swift
//  Vitesse
//
//  Created by Jérôme Kasparian on 25/04/2021.
//

import UIKit
import CoreData

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?  // pour le support iOS 12 : voir https://stackoverflow.com/questions/58405393/appdelegate-and-scenedelegate-when-supporting-ios-12-and-13



    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        UIApplication.shared.isIdleTimerDisabled = true
        luminositeEcranSysteme = UIScreen.main.brightness
        luminositeEstForcee = false
//        print("didfinishlaunchingwithoptions")
        return true
    }

    // MARK: UISceneSession Lifecycle

    @available(iOS 13.0, *)
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    @available(iOS 13.0, *)
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }



    
    func applicationWillEnterForeground(_ application: UIApplication) {
         UIApplication.shared.isIdleTimerDisabled = true
        stoppeLuminositeMax()
        //        enregistrerStats()
    }

    func applicationWillResignActive(_ application: UIApplication) {
        stoppeLuminositeMax()
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        stoppeLuminositeMax()
        enregistrerStats()
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
          UIApplication.shared.isIdleTimerDisabled = true
    }
    
    
    static var orientationLock = UIInterfaceOrientationMask.all

    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return AppDelegate.orientationLock
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        stoppeLuminositeMax()
    }
    
}

@MainActor func enregistrerStats(){
    NotificationCenter.default.post(name: Notification.Name(keyEnregistrerStats), object: nil)
//    userDefaults.set(distanceTotale, forKey: keyDistanceTotale)
//    userDefaults.set(vitesseMax, forKey: keyVitesseMax)
}

@MainActor func stoppeLuminositeMax() {
    if luminositeEstForcee {
        UIScreen.main.brightness = luminositeEcranSysteme
        luminositeEstForcee = false
    }

}

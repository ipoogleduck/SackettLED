//
//  AppDelegate.swift
//  SacketLED
//
//  Created by Oliver Elliott on 10/19/21.
//

import UIKit
import Firebase
import ALRT

var FCMToken: String?

@main
class AppDelegate: UIResponder, UIApplicationDelegate, MessagingDelegate, UNUserNotificationCenterDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        FirebaseApp.configure()
        
        let current = UNUserNotificationCenter.current()

        current.getNotificationSettings(completionHandler: { (settings) in
            if settings.authorizationStatus == .denied {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    let alert = ALRT.create(.alert, title: "Enable Notifications", message: "You won't get important updates or know if you won competitions. Enable notifications by tapping Notifications > Allow Notifications in the settings app.").addCancel()
                    alert.addOK("Open Settings", style: .default, preferred: true, handler: { action, textFields in
                        if let settingsURL = NSURL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.openURL(settingsURL as URL)
                        }
                    })
                    alert.show()
                }
            } else if settings.authorizationStatus != .notDetermined { //Request permissions later instead
                current.requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
                    print("Permission granted: \(granted)")
                    
                }
            }
        })
        
        current.delegate = self
        
        application.registerForRemoteNotifications()
        Messaging.messaging().delegate = self
        
        return true
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert, .badge, .sound])
    }
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        print("Firebase registration token: \(String(describing: fcmToken))")
        if let fcmToken = fcmToken {
            print(fcmToken)
            FCMToken = fcmToken
        }
        let dataDict:[String: String] = ["token": fcmToken ?? ""]
        NotificationCenter.default.post(name: Notification.Name("FCMToken"), object: nil, userInfo: dataDict)
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }


}


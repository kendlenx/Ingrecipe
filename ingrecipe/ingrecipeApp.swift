import SwiftUI
import FirebaseCore
import Firebase

@main
struct ingrecipeApp: App {
    
    init() {
        FirebaseApp.configure()
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { (granted, error) in
                   if granted {
                       DispatchQueue.main.async {
                           UIApplication.shared.registerForRemoteNotifications()
                       }
                   } else {
                       print("Notification permission not granted.")
                   }
               }
    }
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

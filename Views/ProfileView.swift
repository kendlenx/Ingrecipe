import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import UserNotifications

struct ProfileView: View {
    @State private var currentPassword: String = ""
    @State private var newPassword: String = ""
    @State private var confirmPassword: String = ""
    @State private var errorMessage: String = ""
    @State private var successMessage: String = ""
    @State private var enableNotifications: Bool = UserDefaults.standard.bool(forKey: "enableNotifications")
    @State private var selectedReminderOption: Int = UserDefaults.standard.integer(forKey: "selectedReminderOption")
    @State private var isLoggedOut: Bool = false
    @State private var username: String = ""
    @AppStorage("uid") var userID: String = ""

    var body: some View {
        Group {
            if isLoggedOut {
                SignUpView(currentShowingView: .constant("signup"))
            } else {
                NavigationStack {
                    ZStack {
                        ScrollView {
                            VStack(spacing: 30) {
                                VStack {
                                    Text("Welcome, \(username)")
                                        .font(.largeTitle)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                        .multilineTextAlignment(.center)
                                        .shadow(radius: 5)
                                        .padding(.vertical, 30)
                                        .frame(maxWidth: .infinity)
                                }
                                .background(
                                    LinearGradient(gradient: Gradient(colors: [Color.blue, Color.purple]),
                                                   startPoint: .topLeading,
                                                   endPoint: .bottomTrailing)
                                )
                                .cornerRadius(15)
                                .shadow(radius: 8)
                                .padding(.horizontal)

                                VStack(spacing: 20) {
                                    Toggle("Enable Expiration Notifications", isOn: $enableNotifications)
                                        .onChange(of: enableNotifications) { _, newValue in
                                            UserDefaults.standard.set(newValue, forKey: "enableNotifications")
                                            if newValue {
                                                scheduleNotifications()
                                            } else {
                                                removeNotifications()
                                            }
                                        }
                                    
                                    Picker("Reminder Time", selection: $selectedReminderOption) {
                                        Text("1 Day Before").tag(1)
                                        Text("2 Days Before").tag(2)
                                        Text("3 Days Before").tag(3)
                                    }
                                    .pickerStyle(SegmentedPickerStyle())
                                    .padding()
                                    .onChange(of: selectedReminderOption) { _, newValue in
                                        UserDefaults.standard.set(newValue, forKey: "selectedReminderOption")
                                        scheduleNotifications()
                                    }

                                    Text("You will receive reminders about expiration dates.")
                                        .font(.footnote)
                                        .foregroundColor(.gray)
                                }
                                .padding()
                                .background(Color.white)
                                .cornerRadius(12)
                                .shadow(radius: 5)
                                .padding(.horizontal)

                                VStack(spacing: 20) {
                                    Text("Change Password")
                                        .font(.headline)
                                        .foregroundColor(.black)

                                    SecureField("Current Password", text: $currentPassword)
                                        .padding()
                                        .background(Color.white)
                                        .cornerRadius(8)

                                    SecureField("New Password", text: $newPassword)
                                        .padding()
                                        .background(Color.white)
                                        .cornerRadius(8)

                                    SecureField("Confirm Password", text: $confirmPassword)
                                        .padding()
                                        .background(Color.white)
                                        .cornerRadius(8)

                                    Button(action: changePassword) {
                                        Text("Change Password")
                                            .foregroundColor(.white)
                                            .bold()
                                            .frame(maxWidth: .infinity)
                                            .padding()
                                            .background(Color.blue)
                                            .cornerRadius(12)
                                    }
                                }
                                .padding()
                                .background(Color.white.opacity(0.9))
                                .cornerRadius(12)
                                .shadow(radius: 5)
                                .padding(.horizontal)

                                Button(action: logout) {
                                    Text("Logout")
                                        .foregroundColor(.white)
                                        .bold()
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.red)
                                        .cornerRadius(12)
                                }
                                .padding(.horizontal)

                                if !errorMessage.isEmpty {
                                    Text(errorMessage)
                                        .foregroundColor(.red)
                                        .padding()
                                        .background(Color.red.opacity(0.1))
                                        .cornerRadius(8)
                                        .padding(.horizontal)
                                }
                                if !successMessage.isEmpty {
                                    Text(successMessage)
                                        .foregroundColor(.green)
                                        .padding()
                                        .background(Color.green.opacity(0.1))
                                        .cornerRadius(8)
                                        .padding(.horizontal)
                                }

                                Spacer()
                            }
                        }
                    }
                    .onAppear {
                        fetchUsername()
                        
                        if let savedReminderOption = UserDefaults.standard.value(forKey: "selectedReminderOption") as? Int {
                            selectedReminderOption = savedReminderOption
                        }
                    }
                }
            }
        }
    }
    
    func scheduleNotifications() {
        if enableNotifications {
           // let interval: TimeInterval = Double(selectedReminderOption) * 24 * 60 * 60
             let interval: TimeInterval = 10 // 5 saniye içinde bildirim alırsın test etmek için bunu aç
            scheduleNotification(timeInterval: interval)
        }
    }

    func scheduleNotification(timeInterval: TimeInterval) {
        let content = UNMutableNotificationContent()
        content.title = "Expiration Reminder"
        content.body = "Your item will expire soon. Check it out!"
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
        let request = UNNotificationRequest(identifier: "expirationReminder-\(timeInterval)", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error.localizedDescription)")
            }
        }
    }

    func removeNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    func changePassword() {
        if newPassword == confirmPassword {
            successMessage = "Password changed successfully."
            errorMessage = ""
        } else {
            errorMessage = "Passwords do not match."
            successMessage = ""
        }
    }

    func logout() {
        do {
            try Auth.auth().signOut()
            userID = ""
            isLoggedOut = true
        } catch let error {
            errorMessage = "Error signing out: \(error.localizedDescription)"
        }
    }

    func fetchUsername() {
        let db = Firestore.firestore()
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        db.collection("users").document(uid).getDocument { snapshot, error in
            if let error = error {
                print("Error fetching username: \(error.localizedDescription)")
            } else if let data = snapshot?.data(), let fetchedUsername = data["username"] as? String {
                username = fetchedUsername
            }
        }
    }
}

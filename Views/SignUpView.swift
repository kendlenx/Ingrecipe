import SwiftUI
import FirebaseAuth
import FirebaseFirestore

extension String {
    func isValidEmail() -> Bool {
        let emailRegex = "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}$"
        return NSPredicate(format: "SELF MATCHES %@", emailRegex).evaluate(with: self)
    }
    
    func isValidPassword() -> Bool {
        let passwordRegex = "^(?=.*[a-z])(?=.*[$@$#!%*?&])(?=.*[A-Z])(?=.*[0-9]).{8,}$"
        return NSPredicate(format: "SELF MATCHES %@", passwordRegex).evaluate(with: self)
    }
    
    func isValidUsername() -> Bool {
        return count >= 3
    }
}

struct ValidatedTextField: View {
    var placeholder: String
    var icon: String
    @Binding var text: String
    var validation: (String) -> Bool
    var isSecure: Bool = false
    
    @State private var isSecureFieldVisible: Bool = true

    var showValidationIcon: Bool {
        !text.isEmpty
    }

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.gray)
                .accessibilityHidden(true)
            
            if isSecure {
                Group {
                    if isSecureFieldVisible {
                        SecureField(placeholder, text: $text)
                            .autocapitalization(.none)
                    } else {
                        TextField(placeholder, text: $text)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                    }
                }
                
                Button(action: {
                    isSecureFieldVisible.toggle()
                }) {
                    Image(systemName: isSecureFieldVisible ? "eye.slash" : "eye")
                        .foregroundColor(.gray)
                        .accessibilityLabel(isSecureFieldVisible ? "Hide Password" : "Show Password")
                }
            } else {
                TextField(placeholder, text: $text)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
            }
            
            Spacer()
            
            if showValidationIcon {
                Image(systemName: validation(text) ? "checkmark.circle" : "xmark.circle")
                    .foregroundColor(validation(text) ? .green : .red)
            }
        }
        .padding()
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.gray, lineWidth: 1)
        )
    }
}

struct SignUpView: View {
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var username: String = ""
    @State private var errorMessage: String = ""
    @State private var isLoading: Bool = false
    @Binding var currentShowingView: String
    @AppStorage("uid") var userID: String = ""

    private func signUp() {
        guard email.isValidEmail() else {
            errorMessage = "Please enter a valid email."
            return
        }

        guard username.isValidUsername() else {
            errorMessage = "Username must be at least 3 characters."
            return
        }

        guard password.isValidPassword() else {
            errorMessage = "Password must be at least 8 characters, including uppercase, lowercase, numbers, and special characters."
            return
        }

        isLoading = true
        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            self.isLoading = false

            if let error = error {
                self.errorMessage = error.localizedDescription
                return
            }

            guard let user = authResult?.user else { return }

            let db = Firestore.firestore()
            db.collection("users").document(user.uid).setData([
                "username": self.username,
                "email": self.email,
                "uid": user.uid
            ]) { error in
                if let error = error {
                    self.errorMessage = "Failed to save user data: \(error.localizedDescription)"
                } else {
                    user.sendEmailVerification { emailError in
                        if let emailError = emailError {
                            self.errorMessage = "Failed to send verification email: \(emailError.localizedDescription)"
                        } else {
                            self.errorMessage = "Verification email sent. Please check your email."
                        }
                    }

                    try? Auth.auth().signOut()
                    self.errorMessage = "Please verify your email before logging in."
                }
            }
        }
    }


    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            
            VStack {
                HStack {
                    Image("logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 70, height: 70)
                    Text("Sign Up for Ingrecipe!")
                        .font(.largeTitle)
                        .bold()
                }
                .padding(.top, 40)
                
                Spacer()
                
                ValidatedTextField(
                    placeholder: "Username",
                    icon: "person",
                    text: $username,
                    validation: { $0.isValidUsername() }
                )
                .padding(.horizontal)
                
                ValidatedTextField(
                    placeholder: "Email",
                    icon: "envelope",
                    text: $email,
                    validation: { $0.isValidEmail() }
                )
                .padding(.horizontal)
                
                ValidatedTextField(
                    placeholder: "Password",
                    icon: "lock",
                    text: $password,
                    validation: { $0.isValidPassword() },
                    isSecure: true
                )
                .padding(.horizontal)
                
                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding(.top, 8)
                        .padding(.horizontal)
                }
                
                Button(action: signUp) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .padding()
                    } else {
                        Text("Create Account")
                            .foregroundColor(.white)
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.black)
                            .cornerRadius(10)
                    }
                }
                .padding(.horizontal)
                .padding(.top)
                
                Button(action: {
                    withAnimation {
                        currentShowingView = "login"
                    }
                }) {
                    Text("Already have an account?")
                        .font(.footnote)
                        .foregroundColor(.blue)
                }
                .padding(.top, 20)
                
                Spacer()
            }
        }
    }
}

func setupAuthStateListener(currentShowingView: Binding<String>) {
    _ = Auth.auth().addStateDidChangeListener { auth, user in
        if let user = user {
            print("User logged in: \(user.email ?? "Unkown")")
        } else {
            print("User logged out")
        }

        if let user = user {
            if user.isEmailVerified {
                DispatchQueue.main.async {
                    withAnimation {
                        currentShowingView.wrappedValue = "home"
                    }
                }
            } else {
                try? Auth.auth().signOut()
                DispatchQueue.main.async {
                    currentShowingView.wrappedValue = "login"
                }
            }
        } else {
            DispatchQueue.main.async {
                currentShowingView.wrappedValue = "login"
            }
        }
    }
}

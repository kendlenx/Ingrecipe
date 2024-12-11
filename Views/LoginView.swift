import SwiftUI
import FirebaseAuth

struct LoginView: View {
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var errorMessage: String = ""
    @State private var isLoading: Bool = false
    @Binding var currentShowingView: String
    @AppStorage("uid") var userID: String = ""

    private func signInUser() {
        guard !email.isEmpty && !password.isEmpty else {
            errorMessage = "Please fill in all fields."
            return
        }
        
        isLoading = true
        Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
            isLoading = false
            
            if let error = error {
                errorMessage = error.localizedDescription
                return
            }
            
            if let user = authResult?.user {
                if user.isEmailVerified {
                    userID = user.uid
                    withAnimation {
                        currentShowingView = "home"
                    }
                } else {
                    errorMessage = "Please verify your email before logging in."
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
                    Text("Welcome to Ingrecipe!")
                        .font(.largeTitle)
                        .bold()
                }
                .padding(.top, 40)
                
                Spacer()
                
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
                    validation: { !$0.isEmpty },
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
                
                Button(action: signInUser) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .padding()
                    } else {
                        Text("Sign In")
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
                        currentShowingView = "signup"
                    }
                }) {
                    Text("Don't have an account?")
                        .font(.footnote)
                        .foregroundColor(.blue)
                }
                .padding(.top, 20)
                
                Spacer()
            }
        }
    }
}

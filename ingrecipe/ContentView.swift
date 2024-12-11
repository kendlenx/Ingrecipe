import SwiftUI
import FirebaseAuth

struct ContentView: View {
    @AppStorage("uid") var userID: String = ""
    @State private var currentShowingView: String = "signup"
    @State private var favoriteRecipes: [Recipe] = []
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""

    var body: some View {
        Group {
            if userID.isEmpty {
                if currentShowingView == "signup" {
                    SignUpView(currentShowingView: $currentShowingView)
                } else {
                    LoginView(currentShowingView: $currentShowingView)
                }
            } else {
                MainTabView(favoriteRecipes: $favoriteRecipes)
            }
        }
        .onAppear {
            checkUserSession()
        }
        .alert(isPresented: $showError, content: {
            Alert(title: Text("Error"), message: Text(errorMessage), dismissButton: .default(Text("OK")))
        })
    }

    private func checkUserSession() {
        if let user = Auth.auth().currentUser {
            user.reload { error in
                if let error = error {
                    errorMessage = error.localizedDescription
                    showError = true
                    userID = ""
                    currentShowingView = "signup"
                } else if user.isEmailVerified {
                    userID = user.uid
                    currentShowingView = "home"
                } else {
                    errorMessage = "Please verify your email to continue."
                    showError = true
                    userID = ""
                    currentShowingView = "signup"
                }
            }
        } else {
            userID = ""
            currentShowingView = "signup"
        }
    }
}

struct MainTabView: View {
    @Binding var favoriteRecipes: [Recipe]

    var body: some View {
        TabView {
            NavigationView {
                HomeView()
            }
            .tabItem {
                Image(systemName: "house.fill")
                Text("Home")
            }

            NavigationView {
                FavoritesView(favoriteRecipes: $favoriteRecipes)
            }
            .tabItem {
                Image(systemName: "heart.fill")
                Text("Favorites")
            }

            NavigationView {
                AddProductView()
            }
            .tabItem {
                Image(systemName: "fork.knife")
                Text("Ingredients")
            }

            NavigationView {
                ProductListView()
            }
            .tabItem {
                Image(systemName: "cart.fill")
                Text("Products")
            }

            NavigationView {
                ProfileView()
            }
            .tabItem {
                Image(systemName: "person.crop.circle.fill")
                Text("Profile")
            }
        }
    }
}

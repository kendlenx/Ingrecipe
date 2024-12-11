import SwiftUI

struct FavoritesView: View {
    @Binding var favoriteRecipes: [Recipe]

    func removeFavorite(recipe: Recipe) {
        if let index = favoriteRecipes.firstIndex(of: recipe) {
            favoriteRecipes.remove(at: index)
            saveFavoritesToUserDefaults()
        }
    }

    func saveFavoritesToUserDefaults() {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let encoded = try encoder.encode(favoriteRecipes)
            UserDefaults.standard.set(encoded, forKey: "favoriteRecipes")
            print("Favorites saved successfully.")
        } catch {
            print("An error occurred while saving favorites: \(error)")
        }
    }

    func loadFavoritesFromUserDefaults() {
        if let savedData = UserDefaults.standard.data(forKey: "favoriteRecipes") {
            do {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                let decodedFavorites = try decoder.decode([Recipe].self, from: savedData)
                favoriteRecipes = decodedFavorites
                print("Favorites loaded successfully.")
            } catch {
                print("An error occurred while loading favorites: \(error)")
            }
        } else {
            print("No favorite dishes saved in UserDefaults found.")
        }
    }

    var body: some View {
        NavigationView {
            VStack {
                if favoriteRecipes.isEmpty {
                    Spacer()
                    Text("No favorites yet")
                        .font(.title2)
                        .foregroundColor(.gray)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.white.opacity(0.8))
                                .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                        )
                        .padding(.horizontal)
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 20) {
                            ForEach(favoriteRecipes) { recipe in
                                NavigationLink(destination: RecipeDetailView(recipeID: recipe.id)) {
                                    HStack {
                                        RecipeCardView(recipe: recipe)
                                            .transition(.slide)

                                        Spacer()

                                        Image(systemName: "heart.fill")
                                            .foregroundColor(.red)
                                            .font(.system(size: 24))
                                            .padding(.trailing, 10)
                                            .onTapGesture {
                                                withAnimation {
                                                    removeFavorite(recipe: recipe)
                                                }
                                            }
                                    }
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 15)
                                            .fill(Color.white)
                                            .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 3)
                                    )
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .onAppear {
                loadFavoritesFromUserDefaults()
            }
            .onChange(of: favoriteRecipes) { _, _ in
                saveFavoritesToUserDefaults()
            }
            .navigationTitle("Favorites")
            .navigationBarTitleDisplayMode(.inline) 
        }
    }
}

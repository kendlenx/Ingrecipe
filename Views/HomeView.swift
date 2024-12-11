import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct HomeView: View {
    @State private var recipes: [Recipe] = []
    @State private var isLoading = false
    @State private var selectedFilter = Filter(cuisine: nil, diet: nil)
    @State private var favoriteRecipes: [Recipe] = []
    @State private var sortOption: SortOption = .date

    @State private var cuisines: [String] = [
        "Asian", "African", "American", "British", "Cajun", "Caribbean", "Chinese",
        "Eastern European", "European", "French", "German", "Greek", "Indian", "Irish",
        "Italian", "Japanese", "Jewish", "Korean", "Latin American", "Mediterranean",
        "Mexican", "Middle Eastern", "Nordic", "Southern", "Spanish", "Thai", "Vietnamese"
    ]
    @State private var diets: [String] = ["Vegetarian", "Vegan", "Gluten-Free", "Keto", "Paleo"]

    private let spoonacularService = SpoonacularService()
    private let db = Firestore.firestore()

    enum SortOption: String, CaseIterable {
        case date = "Most Recent"
        case favorite = "Favorites"
        case rating = "Rating"
    }

    @State private var isNavigatingToRateReview = false
    @State private var selectedRecipeID: Int? = nil
    @State private var selectedRecipeRating: Double = 0
    @State private var selectedUserID: String? = nil

    var body: some View {
        NavigationStack {
            List {
                filterSection
                sortSection
                recipeSection
            }
            .navigationTitle("Recipes")
            .onAppear {
                loadFavoriteRecipes()
                Task {
                    await loadRecipes()
                }
            }
            .navigationDestination(isPresented: $isNavigatingToRateReview) {
                RateReviewView(
                    recipeID: selectedRecipeID ?? 0,
                    currentRating: selectedRecipeRating
                )
            }
        }
    }

    private var filterSection: some View {
        Section(header: Text("Filter Recipes")) {
            HStack {
                Picker("Cuisine", selection: $selectedFilter.cuisine) {
                    Text("All").tag(nil as String?)
                    ForEach(cuisines, id: \.self) { cuisine in
                        Text(cuisine).tag(cuisine as String?)
                    }
                }
                .pickerStyle(MenuPickerStyle())

                Picker("Diet", selection: $selectedFilter.diet) {
                    Text("All").tag(nil as String?)
                    ForEach(diets, id: \.self) { diet in
                        Text(diet).tag(diet as String?)
                    }
                }
                .pickerStyle(MenuPickerStyle())
            }

            Button(action: {
                Task {
                    await loadRecipes()
                }
            }) {
                Text("Apply Filters")
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(8)
            }
        }
    }

    private var sortSection: some View {
        Section(header: Text("Sort Recipes")) {
            Picker("Sort by", selection: $sortOption) {
                ForEach(SortOption.allCases, id: \.self) { option in
                    Text(option.rawValue).tag(option)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .onChange(of: sortOption) {
                sortRecipes()
            }
        }
    }

    private var recipeSection: some View {
        Section(header: Text("Recipes")) {
            if isLoading {
                ProgressView("Loading Recipes...")
                    .progressViewStyle(CircularProgressViewStyle(tint: .blue))
            } else if recipes.isEmpty {
                Text("No recipes found")
                    .foregroundColor(.gray)
            } else {
                ForEach(recipes) { recipe in
                    recipeCard(for: recipe)
                }
            }
        }
    }

    private func recipeCard(for recipe: Recipe) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            NavigationLink(destination: RecipeDetailView(recipeID: recipe.id)) {
                RecipeCardView(recipe: recipe)
                    .cornerRadius(8)
                    .shadow(radius: 3)
            }
            .buttonStyle(PlainButtonStyle())

            HStack {
                Button(action: {
                    addToFavorites(recipe: recipe)
                }) {
                    HStack(spacing: 5) {
                        Image(systemName: favoriteRecipes.contains(recipe) ? "heart.fill" : "heart")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                            .foregroundColor(favoriteRecipes.contains(recipe) ? .red : .gray)
                        Text(favoriteRecipes.contains(recipe) ? "Added" : "Add to Favorite")
                            .font(.footnote)
                            .foregroundColor(favoriteRecipes.contains(recipe) ? .red : .primary)
                    }
                }
                .buttonStyle(PlainButtonStyle())

                Spacer()

                VStack(alignment: .leading) {
                    Text("Rating:")
                        .font(.footnote)
                        .foregroundColor(.secondary)

                    HStack {
                        ForEach(1...5, id: \.self) { star in
                            Image(systemName: star <= Int(recipe.rating ?? 0) ? "star.fill" : "star")
                                .foregroundColor(star <= Int(recipe.rating ?? 0) ? .yellow : .gray)
                                .onTapGesture {
                                    if let userID = Auth.auth().currentUser?.uid {
                                        self.isNavigatingToRateReview = true
                                        self.selectedRecipeID = recipe.id
                                        self.selectedRecipeRating = recipe.rating ?? 0
                                        self.selectedUserID = userID
                                    }
                                }
                        }
                    }
                }
            }
            .padding(.top, 4)
        }
        .padding(.vertical, 4)
    }

    private func loadRecipes() async {
        isLoading = true
        let fetchedRecipes = await spoonacularService.fetchRecipes(with: selectedFilter)
        DispatchQueue.main.async {
            self.recipes = fetchedRecipes ?? []
            self.sortRecipes()
            self.isLoading = false
        }
    }

    private func sortRecipes() {
        switch sortOption {
        case .date:
            recipes.sort {
                ($0.dateAdded ?? Date.distantPast) > ($1.dateAdded ?? Date.distantPast)
            }
            
        case .favorite:
            recipes.sort {
                let isFavorite1 = favoriteRecipes.contains($0)
                let isFavorite2 = favoriteRecipes.contains($1)
                
                if isFavorite1 == isFavorite2 {
                    return $0.title < $1.title
                }
                return isFavorite1
            }

        case .rating:
            recipes.sort {
                ($0.rating ?? 0.0) > ($1.rating ?? 0.0)
            }
        }
    }


    private func addToFavorites(recipe: Recipe) {
        if favoriteRecipes.contains(where: { $0.id == recipe.id }) {
            favoriteRecipes.removeAll { $0.id == recipe.id }
        } else {
            favoriteRecipes.append(recipe)
        }
        
        saveFavoriteRecipes()
        
        sortRecipes()
    }


    private func saveFavoriteRecipes() {
        if let encodedData = try? JSONEncoder().encode(favoriteRecipes) {
            UserDefaults.standard.set(encodedData, forKey: "favoriteRecipes")
        }
    }

    private func loadFavoriteRecipes() {
        if let savedData = UserDefaults.standard.data(forKey: "favoriteRecipes"),
           let decodedRecipes = try? JSONDecoder().decode([Recipe].self, from: savedData) {
            favoriteRecipes = decodedRecipes
        }
    }
}

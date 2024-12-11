import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct RecipeDetailView: View {
    let recipeID: Int
    @State private var recipe: Recipe?
    @State private var isLoading = true
    @State private var showAllReviews = false
    @State private var currentRating = 0.0
    @State private var isFavorite = false
    @State private var favoriteRecipes: [Recipe] = []
    @State private var reviews: [Review] = []

    var body: some View {
        VStack {
            if isLoading {
                ProgressView("Loading...")
                    .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                    .padding(.top, 50)
            } else if let recipe = recipe {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Text(recipe.title)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)

                        if let imageUrl = URL(string: recipe.image) {
                            AsyncImage(url: imageUrl) { image in
                                image.resizable()
                                    .scaledToFit()
                                    .frame(height: 250)
                            } placeholder: {
                                ProgressView()
                            }
                            .cornerRadius(10)
                        }

                        if let readyInMinutes = recipe.readyInMinutes {
                            Text("Ready in \(readyInMinutes) minutes")
                                .font(.headline)
                                .foregroundColor(.secondary)
                        }

                        if let cuisines = recipe.cuisines, !cuisines.isEmpty {
                            Text("Cuisines: \(cuisines.joined(separator: ", "))")
                                .font(.subheadline)
                        }

                        if let diets = recipe.diets, !diets.isEmpty {
                            Text("Diets: \(diets.joined(separator: ", "))")
                                .font(.subheadline)
                        }

                        if let ingredients = recipe.extendedIngredients {
                            Text("Ingredients")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .padding(.top)

                            ForEach(ingredients, id: \.id) { ingredient in
                                Text("• \(ingredient.original)")
                                    .font(.body)
                                    .foregroundColor(.secondary)
                            }
                        }

                        if let instructions = recipe.instructions {
                            Text("Instructions")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .padding(.top)

                            let instructionLines = removeHTMLTags(from: instructions).split(whereSeparator: \.isNewline)
                            VStack(alignment: .leading, spacing: 20) {
                                ForEach(instructionLines, id: \.self) { line in
                                    Text(line)
                                        .font(.title3)
                                        .foregroundColor(.primary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                            .padding(.top, 10)
                        } else {
                            Text("No instructions available.")
                                .foregroundColor(.gray)
                                .font(.headline)
                                .padding(.top)
                        }

                        if !reviews.isEmpty {
                            Text("Reviews")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .padding(.top)

                            let reviewsToShow = showAllReviews ? reviews : Array(reviews.prefix(3))

                            ForEach(reviewsToShow) { review in
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(review.review)
                                        .font(.headline)
                                        .foregroundColor(.primary)

                                    Text("\(review.date, style: .date)")
                                        .font(.footnote)
                                        .foregroundColor(.gray)
                                }
                                .padding(.bottom, 8)
                            }

                            if reviews.count > 3 {
                                Button(action: {
                                    showAllReviews.toggle()
                                }) {
                                    Text(showAllReviews ? "Show Less" : "Load More...")
                                        .font(.subheadline)
                                        .foregroundColor(.blue)
                                }
                            }
                        } else {
                            Text("No reviews available.")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .padding(.top)
                        }

                        HStack {
                            NavigationLink(destination: RateReviewView(
                                recipeID: recipe.id,
                                currentRating: currentRating
                            )) {
                                HStack {
                                    Image(systemName: "star.bubble.fill")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 18, height: 18)
                                        .foregroundColor(.white)

                                    Text("Rate&Comment")
                                        .font(.headline)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                }
                                .padding()
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color.blue, Color.purple]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(15)
                                .shadow(radius: 5)
                                .frame(maxWidth: .infinity)
                                .padding(.top, 20)
                            }

                            Button(action: {
                                addToFavorites(recipe: recipe)
                            }) {
                                HStack(spacing: 5) {
                                    Image(systemName: isFavorite ? "heart.fill" : "heart")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 20, height: 20)
                                        .foregroundColor(isFavorite ? .red : .gray)
                                    Text(isFavorite ? "Added to Favorites" : "Add to Favorites")
                                        .font(.footnote)
                                        .foregroundColor(isFavorite ? .red : .primary)
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .padding(.top, 20)
                    }
                    .padding()
                }
            } else {
                Text("Failed to load recipe details.")
                    .foregroundColor(.red)
            }
        }
        .onAppear {
            Task {
                await loadRecipeDetail()
                loadFavoriteRecipes()
                checkIfFavorite()
                fetchUserRating()
                fetchReviews()
            }
        }
        .navigationTitle("Recipe Details")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func loadRecipeDetail() async {
        isLoading = true
        let service = SpoonacularService()
        if let detail = await service.fetchRecipeDetails(for: recipeID) {
            DispatchQueue.main.async {
                self.recipe = detail
                self.isLoading = false
            }
        } else {
            isLoading = false
        }
    }

    private func saveRating(rating: Double) {
        guard let userID = Auth.auth().currentUser?.uid else {
            print("User is not logged in.")
            return
        }

        let db = Firestore.firestore()
        let ratingData: [String: Any] = [
            "rating": rating,
            "review": "",
            "userID": userID,
            "timestamp": Timestamp(date: Date())
        ]

        db.collection("recipes")
            .document("\(recipeID)")
            .collection("ratings")
            .document(userID)
            .setData(ratingData) { error in
                if let error = error {
                    print("Error saving rating: \(error.localizedDescription)")
                } else {
                    print("Rating successfully saved!")
                }
            }
    }

    private func fetchUserRating() {
        guard let userID = Auth.auth().currentUser?.uid else {
            print("User is not logged in.")
            return
        }

        let db = Firestore.firestore()

        db.collection("recipes")
            .document("\(recipeID)")
            .collection("ratings")
            .document(userID)
            .getDocument { document, error in
                if let error = error {
                    print("Error fetching user rating: \(error.localizedDescription)")
                    return
                }

                if let document = document, document.exists {
                    if let rating = document.data()?["rating"] as? Double {
                        DispatchQueue.main.async {
                            self.currentRating = rating
                        }
                    }
                }
            }
    }

    private func fetchReviews() {
        let db = Firestore.firestore()
        isLoading = true

        db.collection("recipes")
            .document("\(recipeID)")
            .collection("ratings")
            .order(by: "timestamp", descending: true)
            .getDocuments { snapshot, error in
                isLoading = false
                if let error = error {
                    print("Error fetching reviews: \(error.localizedDescription)")
                    return
                }

                guard let documents = snapshot?.documents, !documents.isEmpty else { return }

                DispatchQueue.main.async {
                    self.reviews = documents.compactMap { doc in
                        let data = doc.data()
                        guard
                            let review = data["review"] as? String,
                            let timestamp = data["timestamp"] as? Timestamp
                        else { return nil }

                        return Review(
                            id: doc.documentID,
                            review: review,
                            date: timestamp.dateValue()
                        )
                    }
                }
            }
    }

    private func addToFavorites(recipe: Recipe) {
        if isFavorite {
            if let index = favoriteRecipes.firstIndex(where: { $0.id == recipe.id }) {
                favoriteRecipes.remove(at: index)
            }
        } else {
            favoriteRecipes.append(recipe)
        }
        isFavorite.toggle()
        saveFavoriteRecipes()
    }

    private func saveFavoriteRecipes() {
        if let encodedData = try? JSONEncoder().encode(favoriteRecipes) {
            UserDefaults.standard.set(encodedData, forKey: "favoriteRecipes")
        }
    }

    private func loadFavoriteRecipes() {
        if let savedData = UserDefaults.standard.data(forKey: "favoriteRecipes"),
           let savedFavorites = try? JSONDecoder().decode([Recipe].self, from: savedData) {
            favoriteRecipes = savedFavorites
        }
    }

    private func checkIfFavorite() {
        isFavorite = favoriteRecipes.contains { $0.id == recipeID }
    }
}

func removeHTMLTags(from html: String) -> String {
    let regex = try! NSRegularExpression(pattern: "<[^>]+>", options: [])
    let range = NSRange(location: 0, length: html.utf16.count)
    let cleanString = regex.stringByReplacingMatches(in: html, options: [], range: range, withTemplate: "")
    return cleanString
}

struct Review: Identifiable, Codable {
    var id: String
    var review: String
    var date: Date
}

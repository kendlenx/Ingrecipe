import FirebaseFirestore

class FirestoreService {
    private let db = Firestore.firestore()

    func fetchRecipes(cuisine: String?, diet: String?, completion: @escaping ([Recipe]) -> Void) {
        var query: Query = db.collection("recipes")

        if let cuisine = cuisine {
            query = query.whereField("cuisine", isEqualTo: cuisine)
        }
        
        if let diet = diet {
            query = query.whereField("diet", isEqualTo: diet)
        }

        query.order(by: "dueDate")
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching recipes: \(error)")
                    completion([])
                    return
                }

                guard let snapshot = snapshot else {
                    completion([])
                    return
                }

                let recipes = snapshot.documents.compactMap { document -> Recipe? in
                    try? document.data(as: Recipe.self)
                }
                completion(recipes)
            }
    }

    func saveRating(for recipeID: Int, userID: String, rating: Double, completion: @escaping (Bool) -> Void) {
        let ratingData: [String: Any] = [
            "rating": rating,
            "timestamp": Timestamp()
        ]
        
        db.collection("recipes")
            .document("\(recipeID)")
            .collection("ratings")
            .document(userID)
            .setData(ratingData) { error in
                if let error = error {
                    print("Error saving rating: \(error)")
                    completion(false)
                } else {
                    print("Rating successfully saved!")
                    completion(true)
                }
            }
    }

    func updateRating(for recipeID: Int, userID: String, newRating: Double, completion: @escaping (Bool) -> Void) {
        let ratingData: [String: Any] = [
            "rating": newRating,
            "timestamp": Timestamp()
        ]
        
        db.collection("recipes")
            .document("\(recipeID)")
            .collection("ratings")
            .document(userID)
            .setData(ratingData, merge: true) { error in
                if let error = error {
                    print("Error updating rating: \(error)")
                    completion(false)
                } else {
                    print("Rating successfully updated!")
                    completion(true)
                }
            }
    }

    func loadRating(for recipeID: Int, userID: String, completion: @escaping (Double?) -> Void) {
        db.collection("recipes")
            .document("\(recipeID)")
            .collection("ratings")
            .document(userID)
            .getDocument { document, error in
                if let error = error {
                    print("Error getting rating: \(error)")
                    completion(nil)
                } else if let document = document, document.exists {
                    if let rating = document.data()?["rating"] as? Double {
                        completion(rating)
                    } else {
                        completion(nil)
                    }
                } else {
                    completion(nil)
                }
            }
    }

    func saveFavoriteRecipes(userID: String, favoriteRecipes: [Recipe], completion: @escaping (Bool) -> Void) {
        let favoriteData: [String: Any] = [
            "favorites": favoriteRecipes.map { $0.id }
        ]
        
        db.collection("users")
            .document(userID)
            .setData(favoriteData, merge: true) { error in
                if let error = error {
                    print("Error saving favorite recipes: \(error)")
                    completion(false)
                } else {
                    print("Favorite recipes successfully saved!")
                    completion(true)
                }
            }
    }

    func loadFavoriteRecipes(userID: String, completion: @escaping ([Recipe]) -> Void) {
        db.collection("users")
            .document(userID)
            .getDocument { document, error in
                if let error = error {
                    print("Error loading favorite recipes: \(error)")
                    completion([])
                    return
                }

                guard let document = document, document.exists,
                      let favoriteRecipeIDs = document.data()?["favorites"] as? [Int] else {
                    completion([])
                    return
                }

                self.fetchRecipesByIDs(favoriteRecipeIDs) { recipes in
                    completion(recipes)
                }
            }
    }

    func fetchRecipesByIDs(_ recipeIDs: [Int], completion: @escaping ([Recipe]) -> Void) {
        var recipes: [Recipe] = []
        let group = DispatchGroup()

        for recipeID in recipeIDs {
            group.enter()
            db.collection("recipes")
                .document("\(recipeID)")
                .getDocument { document, error in
                    if let error = error {
                        print("Error fetching recipe: \(error)")
                    } else if let document = document, document.exists,
                              let recipe = try? document.data(as: Recipe.self) {
                        recipes.append(recipe)
                    }
                    group.leave()
                }
        }

        group.notify(queue: .main) {
            completion(recipes)
        }
    }
}

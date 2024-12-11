import SwiftUI

struct RecipeListView: View {
    @State private var recipes: [Recipe] = []
    @State private var isLoading = false
    @State private var selectedFilter = Filter(cuisine: nil, diet: nil)
    private let spoonacularService = SpoonacularService()

    var productName: String

    var body: some View {
        NavigationView {
            VStack {
                Form {
                    Section(header: Text("Filter Recipes")) {
                        filterSection
                        
                        if isLoading {
                            ProgressView("Loading Recipes...")
                                .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                                .padding()
                        } else {
                            ForEach(recipes) { recipe in
                                NavigationLink(destination: RecipeDetailView(recipeID: recipe.id)) {
                                    VStack(alignment: .leading) {
                                        Text(recipe.title)
                                            .font(.headline)
                                            .padding(.bottom, 5)
                                        
                                        AsyncImage(url: URL(string: recipe.image)) { phase in
                                            switch phase {
                                            case .empty:
                                                ProgressView()
                                                    .progressViewStyle(CircularProgressViewStyle())
                                            case .success(let image):
                                                image
                                                    .resizable()
                                                    .scaledToFit()
                                                    .frame(height: 200)
                                            case .failure:
                                                Image(systemName: "photo.fill")
                                                    .resizable()
                                                    .scaledToFit()
                                                    .frame(height: 200)
                                                    .foregroundColor(.gray)
                                            @unknown default:
                                                EmptyView()
                                            }
                                        }
                                    }
                                    .padding(.vertical, 10)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal)
                .background(Color(UIColor.systemGroupedBackground))
            }
            .navigationTitle("Recipes for \(productName)")
            .onAppear {
                Task {
                    await loadRecipes()
                }
            }
        }
    }

    private var filterSection: some View {
        VStack(alignment: .leading, spacing: 10) {
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


    private func loadRecipes() async {
        isLoading = true
        if let fetchedRecipes = await spoonacularService.fetchRecipes(with: selectedFilter) {
            self.recipes = fetchedRecipes
        }
        self.isLoading = false
    }


    private var cuisines: [String] {
        [
            "Asian", "African", "American", "British", "Cajun", "Caribbean", "Chinese",
            "Eastern European", "European", "French", "German", "Greek", "Indian", "Irish",
            "Italian", "Japanese", "Jewish", "Korean", "Latin American", "Mediterranean",
            "Mexican", "Middle Eastern", "Nordic", "Southern", "Spanish", "Thai", "Vietnamese"
        ]
    }

    private var diets: [String] {
        ["Vegetarian", "Vegan", "Gluten-Free", "Keto", "Paleo"]
    }
}

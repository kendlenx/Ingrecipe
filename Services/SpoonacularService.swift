import Foundation

class SpoonacularService {
    private let apiKey = "22094369f5164fe3aeec9677602f791a" 
    private let baseURL = "https://api.spoonacular.com"
    
    func fetchRecipes(with filter: Filter) async -> [Recipe]? {
        do {
            let url = try createURL(for: "/recipes/complexSearch", with: filter)
            
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                print("HTTP Error: Invalid response status code")
                return nil
            }
            

            let decoder = JSONDecoder()
            let recipeResponse = try decoder.decode(RecipeResponse.self, from: data)
            return recipeResponse.results
        } catch {
            print("Error fetching or decoding recipes: \(error.localizedDescription)")
            return nil
        }
    }
    
    func fetchRecipeDetails(for recipeID: Int) async -> Recipe? {
        let endpoint = "/recipes/\(recipeID)/information"
        do {
            let url = try createURL(for: endpoint)
            
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                print("HTTP Error: Invalid response status code")
                return nil
            }
            

            let decoder = JSONDecoder()
            return try decoder.decode(Recipe.self, from: data)
        } catch {
            print("Error fetching recipe details: \(error.localizedDescription)")
            return nil
        }
    }

    func fetchCuisines() async -> [String] {
        [
            "African", "American", "British", "Cajun", "Caribbean", "Chinese",
            "Eastern European", "European", "French", "German", "Greek", "Indian",
            "Irish", "Italian", "Japanese", "Jewish", "Korean", "Latin American",
            "Mediterranean", "Mexican", "Middle Eastern", "Nordic", "Southern",
            "Spanish", "Thai", "Vietnamese"
        ]
    }
    
    func fetchDiets() async -> [String] {
        ["Vegetarian", "Vegan", "Gluten-Free", "Keto", "Paleo"]
    }
    
    private func createURL(for endpoint: String, with filter: Filter? = nil) throws -> URL {
        var urlComponents = URLComponents(string: "\(baseURL)\(endpoint)")
        var queryItems: [URLQueryItem] = [URLQueryItem(name: "apiKey", value: apiKey)]
        
        if let filter = filter {
            if let cuisine = filter.cuisine {
                queryItems.append(URLQueryItem(name: "cuisine", value: cuisine))
            }
            if let diet = filter.diet {
                queryItems.append(URLQueryItem(name: "diet", value: diet))
            }
        }
        
        urlComponents?.queryItems = queryItems
        
        guard let url = urlComponents?.url else {
            throw URLError(.badURL)
        }
        
        return url
    }
}

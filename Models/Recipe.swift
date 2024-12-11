import Foundation

struct Recipe: Identifiable, Codable, Equatable {
    var id: Int
    let title: String
    let image: String
    let readyInMinutes: Int?
    let cuisines: [String]?
    let diets: [String]?
    let imageType: String?
    let extendedIngredients: [Ingredient]?
    let instructions: String?
    
    var dateAdded: Date?
    var rating: Double?
    
    let reviews: [Review]?

    struct Ingredient: Codable, Equatable {
        let id: Int
        let original: String
    }

    struct Review: Identifiable, Codable, Equatable {
        let id: Int
        let author: String
        let content: String
        let date: Date
    }

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case image
        case readyInMinutes
        case cuisines
        case diets
        case imageType
        case extendedIngredients
        case instructions
        case dateAdded
        case rating
        case reviews 
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(Int.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        image = try container.decode(String.self, forKey: .image)
        readyInMinutes = try container.decodeIfPresent(Int.self, forKey: .readyInMinutes)
        cuisines = try container.decodeIfPresent([String].self, forKey: .cuisines)
        diets = try container.decodeIfPresent([String].self, forKey: .diets)
        imageType = try container.decodeIfPresent(String.self, forKey: .imageType)
        extendedIngredients = try container.decodeIfPresent([Ingredient].self, forKey: .extendedIngredients)
        instructions = try container.decodeIfPresent(String.self, forKey: .instructions)
        
        dateAdded = try container.decodeIfPresent(Date.self, forKey: .dateAdded)
        rating = try container.decodeIfPresent(Double.self, forKey: .rating)
        
        reviews = try container.decodeIfPresent([Review].self, forKey: .reviews)
    }
}

struct RecipeResponse: Codable {
    let results: [Recipe]
    let offset: Int
    let number: Int
    let totalResults: Int

    enum CodingKeys: String, CodingKey {
        case results
        case offset
        case number
        case totalResults
    }
}

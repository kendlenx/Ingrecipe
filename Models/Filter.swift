import Foundation

struct Filter : Equatable {
    var cuisine: String?
    var diet: String?

    func toQueryItems() -> [URLQueryItem] {
        var queryItems: [URLQueryItem] = []
        
        if let cuisine = cuisine {
            queryItems.append(URLQueryItem(name: "cuisine", value: cuisine))
        }
        
        if let diet = diet {
            queryItems.append(URLQueryItem(name: "diet", value: diet))
        }

        return queryItems
    }
}

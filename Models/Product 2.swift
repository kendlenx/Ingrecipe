import SwiftUI
import FirebaseFirestore

// Product Model
struct Product: Identifiable {
    var id: String // Firestore doküman ID'sini tutar
    var name: String
    var quantity: String
    var dueDate: Date
    var isExpired: Bool
    var isApproaching: Bool
    
    init(data: [String: Any], id: String) {
        self.id = id
        self.name = data["name"] as? String ?? ""
        self.quantity = data["quantity"] as? String ?? ""
        self.dueDate = (data["dueDate"] as? Timestamp)?.dateValue() ?? Date()
        self.isExpired = data["isExpired"] as? Bool ?? false
        self.isApproaching = data["isApproaching"] as? Bool ?? false
    }
}

// ProductListView
struct ProductListView: View {
    @State private var products: [Product] = []
    @State private var

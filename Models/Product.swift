import Foundation
import FirebaseFirestore

struct Product: Identifiable {
    var id: String
    var name: String
    var quantity: Int
    var dueDate: Date
    
    var isExpired: Bool {
        dueDate < Date()
    }
    
    var isApproaching: Bool {
        let calendar = Calendar.current
        guard let warningDate = calendar.date(byAdding: .day, value: -7, to: dueDate) else { return false }
        return Date() >= warningDate && !isExpired
    }
    
    init?(data: [String: Any], id: String) {
        guard let name = data["name"] as? String,
              let quantity = data["quantity"] as? Int,
              let dueDate = data["dueDate"] as? Timestamp else {
            return nil
        }
        
        self.id = id
        self.name = name
        self.quantity = quantity
        self.dueDate = dueDate.dateValue()
    }
}

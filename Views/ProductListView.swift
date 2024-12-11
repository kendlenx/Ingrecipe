import SwiftUI
import FirebaseFirestore

struct ProductListView: View {
    @State private var products: [Product] = []
    @State private var isLoading: Bool = true
    private let db = Firestore.firestore()

    var body: some View {
        NavigationView {
            ZStack {
                VStack {
                    if isLoading {
                        ProgressView("Loading products...")
                            .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                            .scaleEffect(1.5, anchor: .center)
                            .padding()
                            .frame(maxHeight: .infinity, alignment: .center)
                    } else {
                        ScrollView {
                            VStack(spacing: 15) {
                                ForEach(products) { product in
                                    ProductRow(
                                        product: product,
                                        onQuantityChange: { id, newQuantity in
                                            updateProductQuantity(id: id, newQuantity: newQuantity)
                                        },
                                        onDelete: { id in
                                            deleteProduct(id: id)
                                        }
                                    )
                                }
                            }
                            .padding(.horizontal)
                        }
                        .frame(maxHeight: .infinity)
                    }
                }
                .safeAreaInset(edge: .top) {
                    Color.clear.frame(height: 1)
                }
            }
            .navigationTitle("Products")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            fetchProducts()
        }

    }

    private func fetchProducts() {
        db.collection("products")
            .order(by: "dueDate", descending: false)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching products: \(error)")
                } else {
                    products = snapshot?.documents.compactMap { document in
                        let data = document.data()
                        return Product(data: data, id: document.documentID)
                    } ?? []
                    isLoading = false
                }
            }
    }

    private func updateProductQuantity(id: String, newQuantity: Int) {
        db.collection("products").document(id).updateData(["quantity": newQuantity]) { error in
            if let error = error {
                print("Error updating quantity: \(error)")
            } else {
                if let index = products.firstIndex(where: { $0.id == id }) {
                    products[index].quantity = newQuantity
                }
            }
        }
    }

    private func deleteProduct(id: String) {
        db.collection("products").document(id).delete { error in
            if let error = error {
                print("Error deleting product: \(error)")
            } else {
                products.removeAll { $0.id == id }
            }
        }
    }
}

struct ProductRow: View {
    var product: Product
    var onQuantityChange: (String, Int) -> Void
    var onDelete: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            NavigationLink(destination: RecipeListView(productName: product.name)) {
                Text("See Recipes")
                    .font(.subheadline)
                    .foregroundColor(.blue)
                    .padding(.bottom, 8)
            }

            HStack {
                Text(product.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .trailing) {
                    Text("Quantity: \(product.quantity)")
                        .font(.subheadline)
                        .foregroundColor(.gray)

                    Text("Expiration Date: \(product.dueDate, style: .date)")
                        .font(.subheadline)
                        .foregroundColor(product.isExpired ? .red : (product.isApproaching ? .orange : .green))
                }
                .padding(.leading)
            }
            .padding(.horizontal)
            .background(RoundedRectangle(cornerRadius: 12)
                            .fill(product.isExpired ? Color.red.opacity(0.1) : (product.isApproaching ? Color.orange.opacity(0.1) : Color.green.opacity(0.1))))
            .cornerRadius(12)
            .shadow(radius: 5, x: 0, y: 2)

            HStack {
                Button(action: {
                    let newQuantity = product.quantity - 1
                    if newQuantity >= 0 {
                        onQuantityChange(product.id, newQuantity)
                    }
                }) {
                    Image(systemName: "minus.circle.fill")
                        .font(.title2)
                        .foregroundColor(.red)
                }

                Button(action: {
                    let newQuantity = product.quantity + 1
                    onQuantityChange(product.id, newQuantity)
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(.green)
                }

                Spacer()

                Button(action: {
                    onDelete(product.id)
                }) {
                    Image(systemName: "trash.fill")
                        .font(.title2)
                        .foregroundColor(.red)
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)

            Divider()
        }
        .padding(.vertical, 8)
    }
}

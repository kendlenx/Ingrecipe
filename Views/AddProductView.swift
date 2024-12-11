import SwiftUI
import FirebaseFirestore

struct AddProductView: View {
    @State private var name: String = ""
    @State private var quantity: Int = 1
    @State private var dueDate: Date = Date()
    @State private var successMessage: String = ""
    @State private var errorMessage: String = ""
    @State private var showAlert: Bool = false
    
    private let db = Firestore.firestore()
    
    var body: some View {
        VStack {
            ScrollView {
                VStack(spacing: 30) {
                    Text("Add New Ingredients")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(Color.blue)
                        .padding(.top, 40)
                    
                    customTextField(placeholder: "Enter ingredient name", text: $name)
                    
                    customStepper(title: "Quantity: \(quantity)", value: $quantity, range: 1...100)
                    
                    customDatePicker(title: "Expiration Date", selection: $dueDate)
                    
                    expirationStatusSection
                    
                }
                .padding(.horizontal)
                .padding(.bottom, 40)
            }
            .background(Color("BackgroundColor").edgesIgnoringSafeArea(.all))
            
            addProductButton
        }
        .padding(.bottom, 20)
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("Success"),
                message: Text(successMessage),
                dismissButton: .default(Text("OK")) {
                    resetFields()
                }
            )
        }
    }
    
    private func customTextField(placeholder: String, text: Binding<String>) -> some View {
        TextField(placeholder, text: text)
            .padding()
            .background(Color.white)
            .cornerRadius(10)
            .shadow(color: Color.gray.opacity(0.2), radius: 5, x: 0, y: 2)
            .padding(.vertical, 5)
    }
    
    private func customStepper(title: String, value: Binding<Int>, range: ClosedRange<Int>) -> some View {
        Stepper(title, value: value, in: range)
            .padding()
            .background(Color.white)
            .cornerRadius(10)
            .shadow(color: Color.gray.opacity(0.2), radius: 5, x: 0, y: 2)
            .padding(.vertical, 5)
    }
    
    private func customDatePicker(title: String, selection: Binding<Date>) -> some View {
        VStack {
            Text(title)
                .font(.headline)
                .padding(.top, 10)
                .foregroundColor(.black)
            DatePicker("", selection: selection, displayedComponents: [.date])
                .datePickerStyle(WheelDatePickerStyle())
                .padding()
                .background(Color.white)
                .cornerRadius(10)
                .shadow(color: Color.gray.opacity(0.2), radius: 5, x: 0, y: 2)
                .padding(.vertical, 5)
        }
    }
    
    private var expirationStatusSection: some View {
        VStack(spacing: 10) {
            if isExpired {
                Text("This product is expired.")
                    .fontWeight(.bold)
                    .foregroundColor(.red)
                    .padding()
            } else if isApproachingExpiration {
                Text("This product is approaching expiration.")
                    .fontWeight(.bold)
                    .foregroundColor(.yellow)
                    .padding()
            } else {
                Text("This product is fresh and not approaching expiration.")
                    .fontWeight(.bold)
                    .foregroundColor(.green)
                    .padding()
            }
        }
    }
    
    private var addProductButton: some View {
        Button(action: {
            saveProduct()
        }) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title)
                    .foregroundColor(.white)
                Text("Add Ingredient")
                    .font(.title3)
                    .bold()
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isFormValid ? Color.blue : Color.gray)
            .cornerRadius(10)
            .shadow(color: Color.blue.opacity(0.2), radius: 5, x: 0, y: 2)
            .padding(.horizontal)
            .padding(.bottom, 30)
        }
        .disabled(!isFormValid)
    }
    
    private var isFormValid: Bool {
        return !name.isEmpty && dueDate > Date()
    }
    
    private func dateOnly(for date: Date) -> Date {
        let calendar = Calendar.current
        return calendar.startOfDay(for: date)
    }
    
    private var isExpired: Bool {
        return dateOnly(for: dueDate) < dateOnly(for: Date())
    }
    
    private var isApproachingExpiration: Bool {
        let calendar = Calendar.current
        let daysUntilExpiration = calendar.dateComponents([.day], from: Date(), to: dueDate).day ?? 0
        
        return daysUntilExpiration >= 0 && daysUntilExpiration <= 7
    }
    
    private func saveProduct() {
        let productData: [String: Any] = [
            "name": name,
            "quantity": quantity,
            "dueDate": Timestamp(date: dueDate),
            "isExpired": isExpired,
            "isApproaching": isApproachingExpiration
        ]
        
        Task {
            do {
                try await db.collection("products").addDocument(data: productData)
                successMessage = "Product added successfully!"
                showAlert = true
            } catch {
                errorMessage = "Error adding product: \(error.localizedDescription)"
                showAlert = true
            }
        }
    }
    
    private func resetFields() {
        name = ""
        quantity = 1
        dueDate = Date()
    }
}

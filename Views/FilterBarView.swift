import SwiftUI

struct FilterBarView: View {
    @Binding var filter: Filter
    var onApply: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            HStack(spacing: 20) {
                Picker("Cuisine", selection: $filter.cuisine) {
                    Text("All").tag(nil as String?)
                    ForEach([ "Asian", "African", "American", "British", "Cajun", "Caribbean", "Chinese",
                              "Eastern European", "European", "French", "German", "Greek", "Indian", "Irish",
                              "Italian", "Japanese", "Jewish", "Korean", "Latin American", "Mediterranean",
                              "Mexican", "Middle Eastern", "Nordic", "Southern", "Spanish", "Thai", "Vietnamese"
                       ], id: \.self) { cuisine in
                        Text(cuisine).tag(cuisine as String?)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .padding(10)
                .background(Color.white)
                .cornerRadius(12)
                .shadow(radius: 5)
                .frame(maxWidth: .infinity)

                Picker("Diet", selection: $filter.diet) {
                    Text("All").tag(nil as String?)
                    ForEach(["Vegetarian", "Vegan", "Gluten-Free", "Keto", "Paleo"], id: \.self) { diet in
                        Text(diet).tag(diet as String?)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .padding(10)
                .background(Color.white)
                .cornerRadius(12)
                .shadow(radius: 5)
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal)
            
            Button(action: {
                onApply()
            }) {
                Text("Apply Filters")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .foregroundColor(.white)
                    .background(LinearGradient(gradient: Gradient(colors: [Color.blue, Color.purple]), startPoint: .leading, endPoint: .trailing))
                    .cornerRadius(12)
                    .shadow(radius: 5)
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(16)
        .shadow(radius: 10)
        .padding()
    }
}

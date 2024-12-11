import SwiftUI
import FirebaseFirestore

struct RateReviewView: View {
    var recipeID: Int
    var currentRating: Double
    
    @State private var rating: Double
    @State private var reviewText: String = ""
    @State private var isSubmitting: Bool = false
    @State private var showToast: Bool = false
    @State private var comments: [Comment] = [
        Comment(user: "John Doe", text: "Great recipe! Loved it."),
        Comment(user: "Jane Smith", text: "Too spicy for me, but the texture was amazing."),
        Comment(user: "Alice Brown", text: "Perfect for dinner parties.")
    ]
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var navigateToHome: Bool = false

    private let db = Firestore.firestore()
    private let maxCharacterCount = 250

    init(recipeID: Int, currentRating: Double) {
        self.recipeID = recipeID
        self.currentRating = currentRating
        _rating = State(initialValue: currentRating)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)]), startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        Text("Rate & Review")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        HStack(spacing: 12) {
                            ForEach(1...5, id: \.self) { star in
                                Image(systemName: star <= Int(rating) ? "star.fill" : "star")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 45, height: 45)
                                    .foregroundColor(star <= Int(rating) ? .yellow : .gray)
                                    .onTapGesture {
                                        rating = Double(star)
                                        triggerHapticFeedback()
                                    }
                                    .scaleEffect(star <= Int(rating) ? 1.2 : 1.0)
                                    .animation(.spring(), value: rating)
                            }
                        }

                        VStack(alignment: .leading) {
                            Text("Your Review")
                                .font(.headline)
                                .padding(.bottom, 5)
                                .foregroundColor(.primary)
                            
                            TextEditor(text: $reviewText)
                                .padding(15)
                                .frame(height: 150)
                                .background(Color(UIColor.systemGray6))
                                .cornerRadius(15)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 15)
                                        .stroke(Color.purple.opacity(0.5), lineWidth: 1)
                                )
                            
                            Text("\(maxCharacterCount - reviewText.count) characters remaining")
                                .font(.caption)
                                .foregroundColor(reviewText.count > maxCharacterCount ? .red : .gray)
                        }
                        .padding()

                        VStack(spacing: 20) {
                            Button(action: saveRating) {
                                if isSubmitting {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Text("Save")
                                        .fontWeight(.semibold)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.green)
                                        .foregroundColor(.white)
                                        .cornerRadius(15)
                                        .shadow(radius: 5)
                                }
                            }
                            .disabled(isSubmitting || reviewText.count > maxCharacterCount)

                            Button(action: {
                                skipRating()
                                dismiss()
                            }) {
                                Text("Skip")
                                    .fontWeight(.semibold)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.red)
                                    .foregroundColor(.white)
                                    .cornerRadius(15)
                                    .shadow(radius: 5)
                            }
                        }
                        .padding(.horizontal)

                        VStack(alignment: .leading, spacing: 12) {
                            Text("Other Reviews")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            ForEach(comments, id: \.id) { comment in
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(comment.user)
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    Text(comment.text)
                                        .font(.body)
                                        .foregroundColor(.gray)
                                }
                                .padding(12)
                                .background(Color(UIColor.systemGray6))
                                .cornerRadius(12)
                                .shadow(radius: 5)
                            }
                        }
                        .padding()
                    }
                    .padding()
                }

                if showToast {
                    VStack {
                        Spacer()
                        ToastView(message: "Review Submitted!")
                    }
                    .transition(.slide)
                    .animation(.easeInOut, value: showToast)
                }
            }
            .background(
                NavigationLink(value: navigateToHome) {
                    EmptyView()
                }
            )
            .navigationDestination(for: Bool.self) { _ in
                HomeView()
            }
        }
    }

    private func saveRating() {
        guard !isSubmitting else { return }
        isSubmitting = true

        dismiss()

        let ratingData: [String: Any] = [
            "rating": rating,
            "review": reviewText,
            "timestamp": Timestamp()
        ]

        db.collection("recipes")
            .document("\(recipeID)")
            .collection("ratings")
            .document(UUID().uuidString)
            .setData(ratingData) { error in
                isSubmitting = false
                if let error = error {
                    print("Error saving rating: \(error.localizedDescription)")
                } else {
                    DispatchQueue.main.async {
                        showToast = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            showToast = false
                        }
                    }
                }
            }
    }



    private func skipRating() {
        print("User skipped rating.")
    }

    private func triggerHapticFeedback() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
}

struct Comment {
    let id = UUID()
    let user: String
    let text: String
}

struct ToastView: View {
    var message: String

    var body: some View {
        Text(message)
            .fontWeight(.bold)
            .padding()
            .background(Color.black.opacity(0.8))
            .foregroundColor(.white)
            .cornerRadius(10)
            .shadow(radius: 5)
            .padding(.horizontal)
    }
}

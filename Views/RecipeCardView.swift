import SwiftUI

struct RecipeCardView: View {
    let recipe: Recipe

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            AsyncImage(url: URL(string: recipe.image)) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                        .frame(height: 200)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(12)
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(height: 200)
                        .clipped()
                        .cornerRadius(12)
                case .failure:
                    Image(systemName: "photo.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 200)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(12)
                @unknown default:
                    EmptyView()
                }
            }
            .shadow(radius: 8)

            Text(recipe.title)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .lineLimit(2)
                .truncationMode(.tail)

            HStack {
                if let minutes = recipe.readyInMinutes {
                    Label("\(minutes) min", systemImage: "clock")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                if let rating = recipe.rating {
                    HStack(spacing: 2) {
                        let roundedRating = Int(rating.rounded()) 
                        ForEach(1...5, id: \.self) { star in
                            Image(systemName: star <= roundedRating ? "star.fill" : "star")
                                .resizable()
                                .frame(width: 14, height: 14)
                                .foregroundColor(star <= roundedRating ? .yellow : .gray)
                        }
                    }
                }
            }

            if let diets = recipe.diets, !diets.isEmpty {
                Text(diets.joined(separator: ", "))
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(radius: 8)
        .padding(.horizontal)
    }
}

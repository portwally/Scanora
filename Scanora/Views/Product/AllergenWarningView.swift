import SwiftUI

// MARK: - Allergen Warning View

struct AllergenWarningView: View {
    let allergens: Set<Allergen>
    let traces: Set<Allergen>

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Allergens section
            if !allergens.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Label {
                        Text("Contains")
                            .font(.subheadline.bold())
                    } icon: {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                    }

                    FlowLayout(spacing: 8) {
                        ForEach(allergens.sortedBySeverity, id: \.self) { allergen in
                            AllergenChip(allergen: allergen, isTrace: false)
                        }
                    }
                }
            }

            // Traces section
            if !traces.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Label {
                        Text("May contain traces of")
                            .font(.subheadline.bold())
                    } icon: {
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundColor(.orange)
                    }

                    FlowLayout(spacing: 8) {
                        ForEach(traces.sortedBySeverity, id: \.self) { allergen in
                            AllergenChip(allergen: allergen, isTrace: true)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.red.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Allergen Chip

struct AllergenChip: View {
    let allergen: Allergen
    let isTrace: Bool

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: allergen.sfSymbol)
                .font(.caption)
            Text(allergen.localizedName)
                .font(.caption)
        }
        .foregroundColor(isTrace ? .orange : .red)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            (isTrace ? Color.orange : Color.red).opacity(0.1)
        )
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(isTrace ? Color.orange.opacity(0.3) : Color.red.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Allergen List View (Detailed)

struct AllergenListView: View {
    let allergens: Set<Allergen>
    let traces: Set<Allergen>

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if !allergens.isEmpty {
                Section {
                    ForEach(allergens.sortedBySeverity, id: \.self) { allergen in
                        AllergenRow(allergen: allergen, isTrace: false)
                    }
                } header: {
                    SectionHeader(title: "Contains", icon: "exclamationmark.triangle.fill", color: .red)
                }
            }

            if !traces.isEmpty {
                Section {
                    ForEach(traces.sortedBySeverity, id: \.self) { allergen in
                        AllergenRow(allergen: allergen, isTrace: true)
                    }
                } header: {
                    SectionHeader(title: "May contain traces of", icon: "exclamationmark.circle.fill", color: .orange)
                }
            }

            if allergens.isEmpty && traces.isEmpty {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("No known allergens")
                        .foregroundColor(.secondary)
                }
                .font(.subheadline)
            }
        }
    }
}

// MARK: - Allergen Row

struct AllergenRow: View {
    let allergen: Allergen
    let isTrace: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: allergen.sfSymbol)
                .font(.title3)
                .foregroundColor(isTrace ? .orange : .red)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(allergen.localizedName)
                    .font(.body)
            }

            Spacer()

            if isTrace {
                Text("Traces")
                    .font(.caption)
                    .foregroundColor(.orange)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.1))
                    .clipShape(Capsule())
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Section Header

struct SectionHeader: View {
    let title: String
    let icon: String
    let color: Color

    var body: some View {
        Label {
            Text(title)
                .font(.subheadline.bold())
        } icon: {
            Image(systemName: icon)
                .foregroundColor(color)
        }
    }
}

// MARK: - Flow Layout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)

        for (index, frame) in result.frames.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + frame.minX, y: bounds.minY + frame.minY),
                proposal: ProposedViewSize(frame.size)
            )
        }
    }

    private func arrangeSubviews(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, frames: [CGRect]) {
        let maxWidth = proposal.width ?? .infinity
        var frames: [CGRect] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)

            if currentX + size.width > maxWidth && currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }

            frames.append(CGRect(origin: CGPoint(x: currentX, y: currentY), size: size))
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
        }

        let totalHeight = currentY + lineHeight
        return (CGSize(width: maxWidth, height: totalHeight), frames)
    }
}

// MARK: - Preview

#Preview("Warning View") {
    AllergenWarningView(
        allergens: [.milk, .gluten, .eggs],
        traces: [.nuts, .soybeans]
    )
    .padding()
}

#Preview("List View") {
    AllergenListView(
        allergens: [.milk, .gluten, .eggs],
        traces: [.nuts, .soybeans]
    )
    .padding()
}

#Preview("No Allergens") {
    AllergenListView(
        allergens: [],
        traces: []
    )
    .padding()
}

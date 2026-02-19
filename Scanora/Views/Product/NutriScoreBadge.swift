import SwiftUI

// MARK: - NutriScore Badge

struct NutriScoreBadge: View {
    let score: NutriScore
    var size: BadgeSize = .medium

    enum BadgeSize {
        case small, medium, large

        var fontSize: CGFloat {
            switch self {
            case .small: return 14
            case .medium: return 18
            case .large: return 24
            }
        }

        var padding: CGFloat {
            switch self {
            case .small: return 6
            case .medium: return 10
            case .large: return 14
            }
        }

        var spacing: CGFloat {
            switch self {
            case .small: return 2
            case .medium: return 4
            case .large: return 6
            }
        }
    }

    var body: some View {
        HStack(spacing: size.spacing) {
            ForEach(NutriScore.allCases, id: \.self) { grade in
                Text(grade.grade)
                    .font(.system(size: size.fontSize, weight: .bold))
                    .foregroundColor(grade == score ? .white : grade.color.opacity(0.6))
                    .frame(minWidth: size.fontSize + 8)
                    .padding(.vertical, size.padding / 2)
                    .padding(.horizontal, size.padding / 2)
                    .background(
                        grade == score
                            ? grade.color
                            : grade.color.opacity(0.15)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(score.accessibilityLabel)
    }
}

// MARK: - Compact NutriScore Badge

struct NutriScoreBadgeCompact: View {
    let score: NutriScore

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "leaf.fill")
                .font(.caption2)
            Text(score.grade)
                .font(.caption.bold())
        }
        .foregroundColor(.white)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(score.color)
        .clipShape(Capsule())
        .fixedSize()
        .accessibilityLabel(score.accessibilityLabel)
    }
}

// MARK: - NOVA Group Badge

struct NovaGroupBadge: View {
    let group: NovaGroup
    var size: NutriScoreBadge.BadgeSize = .medium
    var compact: Bool = false

    var body: some View {
        if compact {
            compactBadge
        } else {
            fullBadge
        }
    }

    private var fullBadge: some View {
        HStack(spacing: 6) {
            Image(systemName: group.icon)
                .font(.system(size: size.fontSize * 0.8))
            VStack(alignment: .leading, spacing: 2) {
                Text("NOVA \(group.rawValue)")
                    .font(.system(size: size.fontSize * 0.7, weight: .bold))
                Text(group.localizedName)
                    .font(.system(size: size.fontSize * 0.6))
                    .lineLimit(1)
            }
        }
        .foregroundColor(.white)
        .padding(.horizontal, size.padding)
        .padding(.vertical, size.padding / 1.5)
        .background(group.color)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .accessibilityElement(children: .combine)
    }

    private var compactBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: group.icon)
                .font(.caption)
            Text("NOVA \(group.rawValue)")
                .font(.caption.bold())
        }
        .foregroundColor(.white)
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(group.color)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .accessibilityElement(children: .combine)
    }
}

// MARK: - EcoScore Badge

struct EcoScoreBadge: View {
    let score: EcoScore
    var compact: Bool = false

    var body: some View {
        if compact {
            compactBadge
        } else {
            fullBadge
        }
    }

    private var fullBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: "leaf.circle.fill")
                .font(.title3)
            VStack(alignment: .leading, spacing: 0) {
                Text("Eco-Score")
                    .font(.caption2)
                Text(score.grade)
                    .font(.headline.bold())
            }
        }
        .foregroundColor(.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(score.color)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var compactBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: "leaf.circle.fill")
                .font(.caption)
            Text("Eco \(score.grade)")
                .font(.caption.bold())
        }
        .foregroundColor(.white)
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(score.color)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Health Scores Row

struct HealthScoresRow: View {
    let nutriScore: NutriScore?
    let novaGroup: NovaGroup?
    let ecoScore: EcoScore?

    private let badgeHeight: CGFloat = 36

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // NutriScore section
            if let nutriScore = nutriScore {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 4) {
                        Text(String(localized: "Nutri-Score"))
                            .font(.subheadline.bold())
                        Text(String(localized: "– Nutritional Quality"))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    NutriScoreBadge(score: nutriScore, size: .small)
                    Text(String(localized: "A = Best, E = Poorest nutritional value"))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            // NOVA and Eco badges section
            if novaGroup != nil || ecoScore != nil {
                HStack(spacing: 12) {
                    if let novaGroup = novaGroup {
                        VStack(alignment: .leading, spacing: 4) {
                            UniformBadge(
                                icon: novaGroup.icon,
                                title: String(localized: "Processing"),
                                value: "\(novaGroup.rawValue)",
                                color: novaGroup.color
                            )
                            .frame(height: badgeHeight)
                            Text(String(localized: "1 = Natural, 4 = Ultra-processed"))
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }

                    if let ecoScore = ecoScore {
                        VStack(alignment: .leading, spacing: 4) {
                            UniformBadge(
                                icon: "leaf.circle.fill",
                                title: String(localized: "Eco-Score"),
                                value: ecoScore.grade,
                                color: ecoScore.color
                            )
                            .frame(height: badgeHeight)
                            Text(String(localized: "Environmental impact"))
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }

            if nutriScore == nil && novaGroup == nil && ecoScore == nil {
                Text("No health scores available")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 16)
    }
}

// MARK: - Uniform Badge

struct UniformBadge: View {
    let icon: String
    let title: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.subheadline)
            VStack(alignment: .leading, spacing: 0) {
                Text(title)
                    .font(.system(size: 9))
                Text(value)
                    .font(.subheadline.bold())
            }
        }
        .foregroundColor(.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(color)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Preview

#Preview("NutriScore Badges") {
    VStack(spacing: 20) {
        ForEach(NutriScore.allCases, id: \.self) { score in
            NutriScoreBadge(score: score)
        }
    }
    .padding()
}

#Preview("Compact Badges") {
    VStack(spacing: 12) {
        ForEach(NutriScore.allCases, id: \.self) { score in
            NutriScoreBadgeCompact(score: score)
        }
    }
    .padding()
}

#Preview("NOVA Badges") {
    VStack(spacing: 12) {
        ForEach(NovaGroup.allCases, id: \.self) { group in
            NovaGroupBadge(group: group)
        }
    }
    .padding()
}

#Preview("Health Scores Row") {
    HealthScoresRow(
        nutriScore: .c,
        novaGroup: .processed,
        ecoScore: .b
    )
}

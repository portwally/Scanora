import SwiftUI

struct ErrorView: View {
    let title: String
    let message: String
    var suggestion: String?
    var retryAction: (() -> Void)?
    var secondaryAction: ErrorAction?

    struct ErrorAction {
        let title: String
        let icon: String?
        let action: () -> Void
    }

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 50))
                .foregroundColor(.orange)

            Text(title)
                .font(.title2.bold())

            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            if let suggestion = suggestion {
                Text(suggestion)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            VStack(spacing: 12) {
                if let retryAction = retryAction {
                    Button(action: retryAction) {
                        Label("Try Again", systemImage: "arrow.clockwise")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                }

                if let secondaryAction = secondaryAction {
                    Button(action: secondaryAction.action) {
                        if let icon = secondaryAction.icon {
                            Label(secondaryAction.title, systemImage: icon)
                        } else {
                            Text(secondaryAction.title)
                        }
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding(.horizontal)
        }
        .padding()
    }
}

// MARK: - Network Error View

struct NetworkErrorView: View {
    let error: NetworkError
    var retryAction: (() -> Void)?
    var contributeAction: (() -> Void)?

    var body: some View {
        ErrorView(
            title: errorTitle,
            message: error.localizedDescription ?? "An error occurred",
            suggestion: error.recoverySuggestion,
            retryAction: error.isRetryable ? retryAction : nil,
            secondaryAction: error.showContributeOption ? .init(
                title: "Add Product",
                icon: "plus.circle",
                action: { contributeAction?() }
            ) : nil
        )
    }

    private var errorTitle: String {
        switch error {
        case .productNotFound: return "Product Not Found"
        case .networkUnavailable: return "No Connection"
        case .timeout: return "Request Timed Out"
        case .rateLimitExceeded: return "Too Many Requests"
        default: return "Error"
        }
    }
}

// MARK: - Camera Permission Error View

struct CameraPermissionErrorView: View {
    var onOpenSettings: (() -> Void)?

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "camera.fill")
                .font(.system(size: 50))
                .foregroundColor(.red)

            Text("Camera Access Required")
                .font(.title2.bold())

            Text("Scanora needs camera access to scan barcodes on food products.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            if let onOpenSettings = onOpenSettings {
                Button(action: onOpenSettings) {
                    Label("Open Settings", systemImage: "gear")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal)
            }
        }
        .padding()
    }
}

// MARK: - Preview

#Preview("Error View") {
    ErrorView(
        title: "Something Went Wrong",
        message: "We couldn't load the product information.",
        suggestion: "Please check your internet connection and try again.",
        retryAction: {}
    )
}

#Preview("Product Not Found") {
    NetworkErrorView(
        error: .productNotFound,
        retryAction: {},
        contributeAction: {}
    )
}

#Preview("Camera Permission") {
    CameraPermissionErrorView(onOpenSettings: {})
}

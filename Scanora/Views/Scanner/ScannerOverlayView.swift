import SwiftUI

struct ScannerOverlayView: View {
    let isScanning: Bool

    // Viewfinder dimensions
    private let viewfinderWidth: CGFloat = 280
    private let viewfinderHeight: CGFloat = 180
    private let cornerLength: CGFloat = 30
    private let cornerLineWidth: CGFloat = 4

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Semi-transparent overlay with cutout
                Rectangle()
                    .fill(Color.black.opacity(0.5))
                    .mask(
                        Rectangle()
                            .fill(Color.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .frame(width: viewfinderWidth, height: viewfinderHeight)
                                    .blendMode(.destinationOut)
                            )
                    )
                    .allowsHitTesting(false)

                // Viewfinder corners
                ViewfinderCornersShape(
                    width: viewfinderWidth,
                    height: viewfinderHeight,
                    cornerLength: cornerLength
                )
                .stroke(
                    isScanning ? Color.white : Color.white.opacity(0.5),
                    style: StrokeStyle(lineWidth: cornerLineWidth, lineCap: .round)
                )

                // Scanning line animation
                if isScanning {
                    ScanningLineView()
                        .frame(width: viewfinderWidth - 40)
                        .offset(y: -viewfinderHeight / 4)
                }

                // Instructions
                VStack {
                    Spacer()
                        .frame(height: geometry.size.height / 2 + viewfinderHeight / 2 + 24)

                    Text(isScanning ? "Point at a barcode" : "Paused")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(.ultraThinMaterial)
                        .cornerRadius(8)

                    Spacer()
                }
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Viewfinder Corners Shape

struct ViewfinderCornersShape: Shape {
    let width: CGFloat
    let height: CGFloat
    let cornerLength: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()

        let centerX = rect.midX
        let centerY = rect.midY

        let left = centerX - width / 2
        let right = centerX + width / 2
        let top = centerY - height / 2
        let bottom = centerY + height / 2

        let cornerRadius: CGFloat = 16

        // Top-left corner
        path.move(to: CGPoint(x: left, y: top + cornerLength))
        path.addLine(to: CGPoint(x: left, y: top + cornerRadius))
        path.addQuadCurve(
            to: CGPoint(x: left + cornerRadius, y: top),
            control: CGPoint(x: left, y: top)
        )
        path.addLine(to: CGPoint(x: left + cornerLength, y: top))

        // Top-right corner
        path.move(to: CGPoint(x: right - cornerLength, y: top))
        path.addLine(to: CGPoint(x: right - cornerRadius, y: top))
        path.addQuadCurve(
            to: CGPoint(x: right, y: top + cornerRadius),
            control: CGPoint(x: right, y: top)
        )
        path.addLine(to: CGPoint(x: right, y: top + cornerLength))

        // Bottom-right corner
        path.move(to: CGPoint(x: right, y: bottom - cornerLength))
        path.addLine(to: CGPoint(x: right, y: bottom - cornerRadius))
        path.addQuadCurve(
            to: CGPoint(x: right - cornerRadius, y: bottom),
            control: CGPoint(x: right, y: bottom)
        )
        path.addLine(to: CGPoint(x: right - cornerLength, y: bottom))

        // Bottom-left corner
        path.move(to: CGPoint(x: left + cornerLength, y: bottom))
        path.addLine(to: CGPoint(x: left + cornerRadius, y: bottom))
        path.addQuadCurve(
            to: CGPoint(x: left, y: bottom - cornerRadius),
            control: CGPoint(x: left, y: bottom)
        )
        path.addLine(to: CGPoint(x: left, y: bottom - cornerLength))

        return path
    }
}

// MARK: - Scanning Line Animation

struct ScanningLineView: View {
    @State private var offset: CGFloat = -60

    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.green.opacity(0),
                        Color.green.opacity(0.8),
                        Color.green.opacity(0)
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(height: 2)
            .offset(y: offset)
            .onAppear {
                withAnimation(
                    .easeInOut(duration: 1.5)
                    .repeatForever(autoreverses: true)
                ) {
                    offset = 60
                }
            }
    }
}

// MARK: - Camera Permission View

struct CameraPermissionView: View {
    let onRequestPermission: () -> Void
    let onOpenSettings: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "camera.fill")
                .font(.system(size: 60))
                .foregroundColor(.secondary)

            Text("Camera Access Required")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Scanora needs camera access to scan barcodes on food products.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            VStack(spacing: 12) {
                Button(action: onRequestPermission) {
                    Text("Allow Camera Access")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                Button(action: onOpenSettings) {
                    Text("Open Settings")
                }
                .buttonStyle(.bordered)
            }
            .padding(.horizontal)
        }
        .padding()
    }
}

// MARK: - Preview

#Preview("Scanning") {
    ScannerOverlayView(isScanning: true)
        .background(Color.gray)
}

#Preview("Paused") {
    ScannerOverlayView(isScanning: false)
        .background(Color.gray)
}

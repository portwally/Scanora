import SwiftUI
import PhotosUI

struct ContributeProductView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: ContributeViewModel
    @State private var showingImageSourcePicker = false
    @State private var showingCamera = false
    @State private var showingPhotoPicker = false
    @State private var selectedPhotoItem: PhotosPickerItem?

    let onSuccess: (() -> Void)?

    init(barcode: String, onSuccess: (() -> Void)? = nil) {
        _viewModel = State(initialValue: ContributeViewModel(barcode: barcode))
        self.onSuccess = onSuccess
    }

    var body: some View {
        NavigationStack {
            Form {
                // Barcode Section
                Section {
                    HStack {
                        Image(systemName: "barcode")
                        Text(viewModel.barcode)
                            .font(.body.monospacedDigit())
                    }
                } header: {
                    Text("Barcode")
                }

                // Product Images Section
                Section {
                    ImagePickerRow(
                        title: "Front of package",
                        image: viewModel.frontImage,
                        onSelect: { viewModel.currentImagePicker = .front; showingImageSourcePicker = true },
                        onRemove: { viewModel.removeImage(for: .front) }
                    )

                    ImagePickerRow(
                        title: "Ingredients list",
                        image: viewModel.ingredientsImage,
                        onSelect: { viewModel.currentImagePicker = .ingredients; showingImageSourcePicker = true },
                        onRemove: { viewModel.removeImage(for: .ingredients) }
                    )

                    ImagePickerRow(
                        title: "Nutrition facts",
                        image: viewModel.nutritionImage,
                        onSelect: { viewModel.currentImagePicker = .nutrition; showingImageSourcePicker = true },
                        onRemove: { viewModel.removeImage(for: .nutrition) }
                    )
                } header: {
                    Text("Photos")
                } footer: {
                    Text("Photos help verify product information and are displayed to other users.")
                }

                // Required Info Section
                Section {
                    TextField("Product name", text: $viewModel.productName)
                    TextField("Brand", text: $viewModel.brand)
                    TextField("Quantity (e.g., 500g, 1L)", text: $viewModel.quantity)
                } header: {
                    Text("Product Information")
                } footer: {
                    Text("Product name is required. Other fields are optional but helpful.")
                }

                // Ingredients Section
                Section {
                    TextEditor(text: $viewModel.ingredientsText)
                        .frame(minHeight: 100)
                } header: {
                    HStack {
                        Text("Ingredients")
                        Spacer()
                        if viewModel.ingredientsImage != nil {
                            Button("Extract Text") {
                                if let image = viewModel.ingredientsImage {
                                    Task {
                                        await viewModel.extractText(from: image, for: .ingredients)
                                    }
                                }
                            }
                            .font(.caption)
                        }
                    }
                } footer: {
                    Text("Copy the ingredients list exactly as shown on the package.")
                }

                // Additional Info Section
                Section {
                    TextField("Categories (e.g., Cereals, Breakfast)", text: $viewModel.categories)
                    TextField("Labels (e.g., Organic, Vegan)", text: $viewModel.labels)
                    TextField("Origin country", text: $viewModel.origins)
                    TextField("Stores (e.g., Continente, Pingo Doce)", text: $viewModel.stores)
                } header: {
                    Text("Additional Information")
                }
            }
            .navigationTitle("Add Product")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Submit") {
                        Task {
                            await viewModel.submit()
                        }
                    }
                    .disabled(!viewModel.isValid || viewModel.isSubmitting)
                }
            }
            .overlay {
                if viewModel.isSubmitting {
                    LoadingOverlay(message: "Submitting product...")
                }
            }
            .confirmationDialog("Add Photo", isPresented: $showingImageSourcePicker) {
                Button("Take Photo") {
                    showingCamera = true
                }
                Button("Choose from Library") {
                    showingPhotoPicker = true
                }
                Button("Cancel", role: .cancel) {}
            }
            .sheet(isPresented: $showingCamera) {
                CameraImagePicker { image in
                    if let type = viewModel.currentImagePicker {
                        viewModel.setImage(image, for: type)
                    }
                }
            }
            .photosPicker(
                isPresented: $showingPhotoPicker,
                selection: $selectedPhotoItem,
                matching: .images
            )
            .onChange(of: selectedPhotoItem) { _, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                       let image = UIImage(data: data),
                       let type = viewModel.currentImagePicker {
                        viewModel.setImage(image, for: type)
                    }
                }
            }
            .alert("OCR Result", isPresented: $viewModel.showOCRResult) {
                Button("Use This Text") {
                    viewModel.useOCRText()
                }
                Button("Discard", role: .cancel) {
                    viewModel.discardOCRText()
                }
            } message: {
                Text("Extracted text:\n\n\(viewModel.ocrText.prefix(200))...")
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) {}
            } message: {
                if let message = viewModel.errorMessage {
                    Text(message)
                }
            }
            .alert("Success!", isPresented: $viewModel.showSuccess) {
                Button("Done") {
                    onSuccess?()
                    dismiss()
                }
            } message: {
                Text("Thank you for contributing to Open Food Facts! Your submission will be reviewed and made available to everyone.")
            }
        }
    }
}

// MARK: - Image Picker Row

struct ImagePickerRow: View {
    let title: String
    let image: UIImage?
    let onSelect: () -> Void
    let onRemove: () -> Void

    var body: some View {
        HStack {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemGray5))
                    .frame(width: 60, height: 60)
                    .overlay {
                        Image(systemName: "camera")
                            .foregroundColor(.secondary)
                    }
            }

            Text(title)

            Spacer()

            if image != nil {
                Button(action: onRemove) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            } else {
                Button(action: onSelect) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.accentColor)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Camera Image Picker

struct CameraImagePicker: UIViewControllerRepresentable {
    let onImageCaptured: (UIImage) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onImageCaptured: onImageCaptured)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onImageCaptured: (UIImage) -> Void

        init(onImageCaptured: @escaping (UIImage) -> Void) {
            self.onImageCaptured = onImageCaptured
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                onImageCaptured(image)
            }
            picker.dismiss(animated: true)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}

// MARK: - Preview

#Preview {
    ContributeProductView(barcode: "1234567890123")
}

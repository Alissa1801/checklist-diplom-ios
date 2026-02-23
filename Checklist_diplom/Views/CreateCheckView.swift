import SwiftUI
import PhotosUI

struct CreateCheckView: View {
    @StateObject private var zonesViewModel = ZonesViewModel()
    @StateObject private var checksViewModel = ChecksViewModel()
    @State private var selectedZoneId: Int?
    @State private var selectedImage: UIImage?
    @State private var isSubmitting = false
    @State private var showSuccess = false
    @State private var createdCheck: Check?
    @State private var showingResult = false
    @State private var activeSheet: ActiveSheet?
    @State private var roomNumber: String = ""
    
    enum ActiveSheet: Identifiable {
        case imagePicker
        case camera
        
        var id: Int {
            switch self {
            case .imagePicker: return 1
            case .camera: return 2
            }
        }
    }
    
    var selectedZone: Zone? {
        zonesViewModel.zones.first { $0.id == selectedZoneId }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Информация об объекте")) {
                    TextField("Номер комнаты", text: $roomNumber)
                    .keyboardType(.numberPad) // Оптимально для цифр
                }
                // Выбор зоны
                Section(header: Text("Зона уборки")) {
                    Picker("Выберите зону", selection: $selectedZoneId) {
                        Text("Не выбрано").tag(nil as Int?)
                        ForEach(zonesViewModel.zones) { zone in
                            Text(zone.name).tag(zone.id as Int?)
                        }
                    }
                }
                
                // Фото
                Section(header: Text("Фотография")) {
                    if let image = selectedImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 200)
                            .cornerRadius(10)
                        
                        Button("Удалить фото") {
                            selectedImage = nil
                        }
                        .foregroundColor(.red)
                    } else {
                        HStack {
                            Button(action: {
                                activeSheet = .camera
                            }) {
                                Label("Сделать фото", systemImage: "camera")
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                activeSheet = .imagePicker
                            }) {
                                Label("Выбрать из галереи", systemImage: "photo")
                            }
                        }
                    }
                }
                
                // Кнопка отправки
                Section {
                    if isSubmitting {
                        HStack {
                            Spacer()
                            ProgressView("Отправка...")
                            Spacer()
                        }
                    } else {
                        Button(action: submitCheck) {
                            Text("Отправить на проверку")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .multilineTextAlignment(.center)
                        }
                        .disabled(selectedZoneId == nil || selectedImage == nil || roomNumber.isEmpty)
                    }
                }
            }
            .navigationTitle("Новая проверка")
            .sheet(item: $activeSheet) { sheet in
                switch sheet {
                case .imagePicker:
                    ImagePicker(image: $selectedImage)
                case .camera:
                    CameraView(image: $selectedImage)
                }
            }
            .alert("Успешно!", isPresented: $showSuccess) {
                Button("OK") {
                    showingResult = true
                }
            } message: {
                Text("Проверка отправлена на анализ нейросетью")
            }
            .navigationDestination(isPresented: $showingResult) {
                if let check = createdCheck {
                    SimpleCheckResultView(check: check)
                }
            }
        }
        .onAppear {
            Task {
                await zonesViewModel.fetchZones()
            }
        }
    }
    
    private func submitCheck() {
        guard let zoneId = selectedZoneId else { return }
        
        isSubmitting = true
        
        Task {
            do {
                // Убрали notes из вызова
                let check = try await checksViewModel.createCheck(
                    zoneId: zoneId,
                    roomNumber: roomNumber,
                    image: selectedImage
                )
                
                await MainActor.run {
                    self.createdCheck = check
                    self.showSuccess = true
                    self.isSubmitting = false
                    // Сброс формы
                    self.selectedZoneId = nil
                    self.selectedImage = nil
                    self.roomNumber = ""
                }
            } catch {
                await MainActor.run {
                    self.isSubmitting = false
                    print("Error creating check: \(error)")
                }
            }
        }
    }
}

// MARK: - ImagePicker (исправленная версия)
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            
            guard let provider = results.first?.itemProvider,
                  provider.canLoadObject(ofClass: UIImage.self) else { return }
            
            provider.loadObject(ofClass: UIImage.self) { [weak self] image, _ in
                DispatchQueue.main.async {
                    self?.parent.image = image as? UIImage
                }
            }
        }
    }
}

// MARK: - CameraView (исправленная версия)
struct CameraView: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .camera
        picker.allowsEditing = true
        picker.cameraCaptureMode = .photo
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraView
        
        init(_ parent: CameraView) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage {
                parent.image = image
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

// MARK: - Simple Check Result View
struct SimpleCheckResultView: View {
    let check: Check
    
    // Вычисляем иконку в зависимости от статуса
    private var statusIcon: String {
        switch check.status {
        case 0: return "clock.circle.fill"           // Создана
        case 1: return "hourglass.circle.fill"       // В обработке
        case 2: return "checkmark.circle.fill"       // Одобрена
        case 3: return "xmark.circle.fill"           // Отклонена
        default: return "questionmark.circle.fill"   // Неизвестно
        }
    }
    
    // Вычисляем цвет в зависимости от статуса
    private var statusColor: Color {
        switch check.status {
        case 0: return .orange                       // Создана
        case 1: return .blue                         // В обработке
        case 2: return .green                        // Одобрена
        case 3: return .red                          // Отклонена
        default: return .gray                        // Неизвестно
        }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: statusIcon)
                .font(.system(size: 80))
                .foregroundColor(statusColor)
            
            Text(check.statusText)
                .font(.largeTitle)
                .fontWeight(.bold)
            
            if let score = check.score {
                Text("Оценка: \(Int(score))%")
                    .font(.title2)
                    .foregroundColor(.secondary)
            }
            
            if let analysis = check.analysisResult, let feedback = analysis.feedback {
                Text(feedback)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()
            }
            
            Spacer()
            
            Text("Проверка успешно создана!")
                .font(.headline)
                .foregroundColor(.green)
        }
        .padding()
        .navigationTitle("Результат")
        .navigationBarTitleDisplayMode(.inline)
    }
}

import Foundation
import UIKit
import Combine

class ChecksViewModel: ObservableObject {
    @Published var checks: [Check] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedZone: Zone?
    @Published var isCreatingCheck = false
    
    private let apiService = APIService.shared
    
    func fetchChecks() async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            let fetchedChecks = try await apiService.fetchChecks()
            
            await MainActor.run {
                self.checks = fetchedChecks.sorted { $0.id > $1.id }
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
    
    func createCheck(zoneId: Int, image: UIImage?) async throws -> Check {
        guard let image = image else {
            throw NSError(domain: "ChecksViewModel", code: 1, userInfo: [NSLocalizedDescriptionKey: "Фото обязательно"])
        }
        
        // Сжимаем фото до 5MB
        guard let imageData = compressImage(image, maxSizeInMB: 5.0) else {
            throw NSError(domain: "ChecksViewModel", code: 2, userInfo: [NSLocalizedDescriptionKey: "Не удалось обработать фото"])
        }
        
        print("Отправка фото: \(Double(imageData.count) / 1024 / 1024) MB")
        
        return try await apiService.createCheck(
            zoneId: zoneId,
            imageData: imageData
        )
    }
    
    private func compressImage(_ image: UIImage, maxSizeInMB: Double) -> Data? {
        var compression: CGFloat = 0.9
        let maxSize = Int(maxSizeInMB * 1024 * 1024) // Конвертируем MB в байты
        
        guard var imageData = image.jpegData(compressionQuality: compression) else {
            return nil
        }
        
        // Уменьшаем качество пока не достигнем нужного размера
        while imageData.count > maxSize && compression > 0.1 {
            compression -= 0.1
            if let newData = image.jpegData(compressionQuality: compression) {
                imageData = newData
            } else {
                break
            }
        }
        
        return imageData
    }
}

import Foundation
import SwiftUI
import Combine

class DashboardViewModel: ObservableObject {
    @Published var stats: DashboardStats?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isPersonalStats = false
    
    // Свойство для фильтрации: "day", "week", "month" или "all"
    @Published var selectedPeriod: String = "all"
    
    func fetchStats(userId: Int?, isAdmin: Bool) async {
        await MainActor.run {
            self.isLoading = true
            self.errorMessage = nil
        }
        
        print("🔄 fetchStats called: userId=\(userId ?? -1), isAdmin=\(isAdmin), period=\(selectedPeriod)")
        
        do {
            // 1. Если админ — запрашиваем общую статистику системы с учетом периода
            if isAdmin {
                print("📊 Админ обнаружен. Запрашиваем общую статистику системы (период: \(selectedPeriod))...")
                let response = try await APIService.shared.fetchDashboardStats(period: selectedPeriod)
                
                await MainActor.run {
                    print("✅ Общая статистика получена")
                    self.stats = response
                    self.isPersonalStats = false // Флаг для отображения имен в UI
                }
            }
            // 2. Если не админ, но есть ID — запрашиваем личную статистику с учетом периода
            else if let id = userId {
                print("📊 Запрашиваем личную статистику для userId=\(id) (период: \(selectedPeriod))")
                let response = try await APIService.shared.fetchPersonalStats(userId: id, period: selectedPeriod)
                
                await MainActor.run {
                    print("✅ Личная статистика получена")
                    self.stats = response
                    self.isPersonalStats = true // Флаг для скрытия имен в UI
                }
            } else {
                throw APIError.serverError("Недостаточно данных для получения статистики")
            }
            
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                print("❌ Error fetching stats: \(error)")
            }
        }
        
        await MainActor.run {
            self.isLoading = false
        }
    }
}

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
            // Теперь используем обновленный метод APIService.shared.fetchDashboardStats
            // Он универсален и для админа, и для личной статистики
            
            let response = try await APIService.shared.fetchDashboardStats(
                period: selectedPeriod,
                userId: userId,
                isAdmin: isAdmin
            )
            
            await MainActor.run {
                print("✅ Статистика получена (isAdmin: \(isAdmin))")
                self.stats = response
                // Если мы зашли как админ, то это НЕ персональная статистика (isPersonalStats = false)
                // Если как обычный юзер, то персональная (isPersonalStats = true)
                self.isPersonalStats = !isAdmin
                self.isLoading = false
            }
            
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
                print("❌ Error fetching stats: \(error)")
            }
        }
    }
}

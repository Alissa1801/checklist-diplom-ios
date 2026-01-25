import Foundation
import SwiftUI
import Combine

class DashboardViewModel: ObservableObject {
    @Published var stats: DashboardStats?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let apiService = APIService.shared
    
    func fetchStats() async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            let fetchedStats = try await apiService.fetchDashboardStats()
            
            await MainActor.run {
                self.stats = fetchedStats
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
}

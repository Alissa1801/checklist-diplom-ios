import Foundation
import SwiftUI
import Combine

class ZonesViewModel: ObservableObject {
    @Published var zones: [Zone] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let apiService = APIService.shared
    
    func fetchZones() async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            let fetchedZones = try await apiService.fetchZones()
            
            await MainActor.run {
                self.zones = fetchedZones
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

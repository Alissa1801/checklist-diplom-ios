import Foundation
import SwiftUI
import Combine

class AuthViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let apiService = APIService.shared
    private let userKey = "current_user_data"
    
    var isAdmin: Bool {
        return currentUser?.admin == true
    }
    
    var userId: Int? {
        return currentUser?.id
    }
    
    init() {
        loadSavedUser()
        checkAuthentication()
    }
    
    private func loadSavedUser() {
        // Загружаем сохраненного пользователя
        if let data = UserDefaults.standard.data(forKey: userKey),
           let user = try? JSONDecoder().decode(User.self, from: data) {
            self.currentUser = user
            print("✅ Загружен сохраненный пользователь: \(user.email)")
        }
    }
    
    private func saveUser(_ user: User) {
        // Сохраняем пользователя
        if let encoded = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(encoded, forKey: userKey)
            print("💾 Пользователь сохранен: \(user.email)")
        }
    }
    
    private func clearSavedUser() {
        // Удаляем сохраненного пользователя
        UserDefaults.standard.removeObject(forKey: userKey)
        print("🗑️ Пользователь удален из хранилища")
    }
    
    func checkAuthentication() {
        isAuthenticated = apiService.isLoggedIn
        print(" Проверка аутентификации: \(isAuthenticated)")
    }
    
    func login(email: String, password: String) async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            let response = try await apiService.login(email: email, password: password)
            
            await MainActor.run {
                self.currentUser = response.user
                self.saveUser(response.user)  // ← Сохраняем!
                self.isAuthenticated = true
                self.isLoading = false
                print("✅ Вход выполнен: \(response.user.email), ID: \(response.user.id)")
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
                print("❌ Ошибка входа: \(error)")
            }
        }
    }
    
    func logout() async {
        do {
            _ = try await apiService.logout()
            
            await MainActor.run {
                self.currentUser = nil
                self.clearSavedUser()  // ← Удаляем!
                self.isAuthenticated = false
                print("👋 Выход выполнен")
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                print("❌ Ошибка выхода: \(error)")
            }
        }
    }
}

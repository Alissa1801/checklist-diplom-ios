import SwiftUI

struct ContentView: View {
    @StateObject private var authViewModel = AuthViewModel()
    
    var body: some View {
        Group {
            if authViewModel.isAuthenticated {
                MainTabView()
                    .environmentObject(authViewModel)
            } else {
                LoginView()
                    .environmentObject(authViewModel)
            }
        }
    }
}

struct MainTabView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        TabView {
            ZonesView()
                .tabItem {
                    Label("Зоны", systemImage: "list.bullet")
                }
            
            CreateCheckView()
                .tabItem {
                    Label("Проверить", systemImage: "camera")
                }
            
            ChecksHistoryView()
                .tabItem {
                    Label("История", systemImage: "clock.arrow.circlepath")
                }
            
            // УМНАЯ ВКЛАДКА СТАТИСТИКИ
            Group {
                if authViewModel.isAdmin {
                    DashboardView(userId: nil, isAdmin: true, title: "Статистика системы")
                    } else {
                        DashboardView(userId: authViewModel.userId, isAdmin: false, title: "Моя статистика")
                    }
            }
            .tabItem {
                Label("Статистика", systemImage: "chart.bar")
            }
            
            ProfileView()
                .tabItem {
                    Label("Профиль", systemImage: "person")
                }
        }
    }
}

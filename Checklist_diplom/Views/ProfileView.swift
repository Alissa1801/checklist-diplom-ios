import SwiftUI
import Combine

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showingLogoutAlert = false
    
    var body: some View {
        NavigationView {
            List {
                // Информация о пользователе
                if let user = authViewModel.currentUser {
                    Section {
                        HStack {
                            // Аватар
                            Circle()
                                .fill(Color.blue.opacity(0.3))
                                .frame(width: 60, height: 60)
                                .overlay(
                                    Text(user.firstName.prefix(1) + user.lastName.prefix(1))
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.blue)
                                )
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(user.fullName)
                                    .font(.headline)
                                
                                Text(user.email)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                if let phone = user.phone {
                                    Text(phone)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.leading, 10)
                        }
                        .padding(.vertical, 10)
                    }
                }
                
                // Статистика
                Section(header: Text("Статистика")) {
                    NavigationLink(destination: DashboardView()) {
                        Label("Дашборд", systemImage: "chart.bar")
                    }
                    
                    NavigationLink(destination: ChecksHistoryView()) {
                        Label("Мои проверки", systemImage: "list.bullet")
                    }
                }
                
                // Настройки
                Section(header: Text("Настройки")) {
                    NavigationLink(destination: SettingsView()) {
                        Label("Настройки приложения", systemImage: "gearshape")
                    }
                    
                    Button(action: {
                        showingLogoutAlert = true
                    }) {
                        Label("Выйти", systemImage: "rectangle.portrait.and.arrow.right")
                            .foregroundColor(.red)
                    }
                }
                
                // Информация
                Section(header: Text("О приложении")) {
                    HStack {
                        Text("Версия")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("1.0.0")
                    }
                    
                    HStack {
                        Text("Сервер")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("localhost:3000")
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Профиль")
            .alert("Выход", isPresented: $showingLogoutAlert) {
                Button("Отмена", role: .cancel) { }
                Button("Выйти", role: .destructive) {
                    Task {
                        await authViewModel.logout()
                    }
                }
            } message: {
                Text("Вы уверены, что хотите выйти?")
            }
        }
    }
}

struct SettingsView: View {
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("autoUploadPhotos") private var autoUploadPhotos = true
    @AppStorage("imageQuality") private var imageQuality = 0.8
    
    var body: some View {
        Form {
            Section(header: Text("Уведомления")) {
                Toggle("Включить уведомления", isOn: $notificationsEnabled)
            }
            
            Section(header: Text("Фотографии")) {
                Toggle("Автоматическая загрузка", isOn: $autoUploadPhotos)
                
                VStack(alignment: .leading) {
                    Text("Качество фото: \(Int(imageQuality * 100))%")
                        .font(.subheadline)
                    
                    Slider(value: $imageQuality, in: 0.1...1.0, step: 0.1)
                }
                .padding(.vertical, 5)
            }
            
            Section(header: Text("О приложении")) {
                HStack {
                    Text("Версия API")
                    Spacer()
                    Text("v1")
                        .foregroundColor(.secondary)
                }
                
                NavigationLink("Лицензия") {
                    LicenseView()
                }
            }
        }
        .navigationTitle("Настройки")
    }
}

struct LicenseView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Лицензионное соглашение")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("""
                Цифровой чек-лист - система контроля качества уборки.
                
                Copyright © 2025 Все права защищены.
                
                Данное приложение предназначено для демонстрации возможностей системы автоматизированного контроля качества уборки с использованием компьютерного зрения.
                
                Разработано в рамках выпускной квалификационной работы.
                
                API сервер: Ruby on Rails
                Мобильное приложение: SwiftUI
                
                Для работы требуется подключение к локальному серверу.
                """)
                .font(.body)
                .foregroundColor(.secondary)
                .lineSpacing(5)
                
                Spacer()
            }
            .padding()
        }
        .navigationTitle("Лицензия")
    }
}

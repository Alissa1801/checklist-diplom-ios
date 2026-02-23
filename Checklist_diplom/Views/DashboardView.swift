import SwiftUI

struct DashboardView: View {
    // Параметры для универсальности
    let userId: Int?
    let isAdmin: Bool
    let title: String
    
    @StateObject private var viewModel = DashboardViewModel()
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 15) {
                    
                    // 1. Выбор периода
                    Picker("Период", selection: $viewModel.selectedPeriod) {
                        Text("День").tag("day")
                        Text("Неделя").tag("week")
                        Text("Месяц").tag("month")
                        Text("Все").tag("all")
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    .disabled(viewModel.isLoading)
                    .onChange(of: viewModel.selectedPeriod) { _ in
                        fetchData()
                    }
                    
                    // 2. Заголовок
                    VStack(spacing: 4) {
                        Text(title)
                            .font(.title)
                            .fontWeight(.bold)
                            .padding(.top)
                        
                        if !isAdmin {
                            Text(authViewModel.currentUser?.fullName ?? "")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if viewModel.isLoading {
                        ProgressView("Загрузка данных...")
                            .frame(height: 300)
                    } else if let error = viewModel.errorMessage {
                        VStack(spacing: 10) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.largeTitle)
                                .foregroundColor(.orange)
                            Text(error)
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                            Button("Повторить") { fetchData() }
                        }
                        .padding()
                        .frame(height: 300)
                    } else if let stats = viewModel.stats {
                        
                        // 3. Основные карточки
                        OverviewCard(stats: stats.stats.overview)
                        
                        QualityCard(stats: stats.stats.quality)
                        
                        // 4. Блок только для АДМИНА
                        if isAdmin {
                            if let usersStats = stats.stats.users {
                                UsersCard(stats: usersStats)
                            }
                            
                            LeaderboardCard(leaderboard: stats.stats.leaderboard)
                        }
                        
                        // 5. Последние проверки
                        RecentChecksCard(
                            checks: stats.stats.recentChecks,
                            isPersonal: !isAdmin
                        )
                    }
                }
                .padding()
            }
            .navigationTitle("Аналитика")
            .navigationBarTitleDisplayMode(.inline)
            .refreshable {
                fetchData()
            }
        }
        .onAppear {
            fetchData()
        }
    }
    
    private func fetchData() {
        Task {
            await viewModel.fetchStats(
                userId: userId,
                isAdmin: isAdmin
            )
        }
    }
}

// MARK: - Вспомогательные компоненты

struct OverviewCard: View {
    let stats: DashboardStats.OverviewStats
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Обзор")
                .font(.headline)
            
            HStack(spacing: 15) {
                StatCard(title: "Всего", value: "\(stats.totalChecks)", icon: "list.bullet", color: .blue)
                StatCard(title: "Одобрено", value: "\(stats.approved)", icon: "checkmark.circle.fill", color: .green)
                StatCard(title: "В работе", value: "\(stats.pending)", icon: "clock.fill", color: .orange)
            }
            
            HStack {
                Text("Процент одобрения:")
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(String(format: "%.1f", stats.approvalRate))%")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(stats.approvalRate > 50 ? .green : .orange)
            }
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(15)
    }
}

struct QualityCard: View {
    let stats: DashboardStats.QualityStats
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Качество")
                .font(.headline)
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Ср. оценка")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("\(String(format: "%.1f", stats.averageScore))%")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(stats.averageScore > 90 ? .green : .orange)
                }
                Spacer()
                VStack(alignment: .trailing) {
                    Text("С фото")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("\(stats.checksWithPhoto)")
                        .font(.title)
                        .fontWeight(.semibold)
                }
            }
            
            HStack {
                Text("Фото на проверку:")
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(String(format: "%.1f", stats.photosPerCheck))")
                    .font(.title2)
                    .fontWeight(.medium)
            }
        }
        .padding()
        .background(Color.green.opacity(0.1))
        .cornerRadius(15)
    }
}

struct UsersCard: View {
    let stats: DashboardStats.UsersStats
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Команда")
                .font(.headline)
            
            HStack(spacing: 15) {
                StatCard(title: "Всего", value: "\(stats.totalUsers)", icon: "person.2.fill", color: .purple)
                StatCard(title: "Активных", value: "\(stats.activeUsers)", icon: "person.fill.checkmark", color: .green)
            }
        }
        .padding()
        .background(Color.purple.opacity(0.1))
        .cornerRadius(15)
    }
}

struct RecentChecksCard: View {
    let checks: [DashboardStats.RecentCheck]
    let isPersonal: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(isPersonal ? "История" : "Последние события")
                .font(.headline)
            
            if checks.isEmpty {
                Text("Нет данных").font(.caption).foregroundColor(.secondary)
            } else {
                let items = Array(checks.prefix(5))
                ForEach(items, id: \.id) { check in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(check.zoneName).font(.subheadline).bold()
                            if !isPersonal {
                                Text(check.userName ?? "Сотрудник").font(.caption).foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                        
                        Text(formatStatus(check.status))
                            .font(.system(size: 10, weight: .bold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(statusColor(check.status).opacity(0.15))
                            .foregroundColor(statusColor(check.status))
                            .cornerRadius(6)
                    }
                    Divider()
                }
            }
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(15)
    }
    
    // ИСПРАВЛЕНО: статус теперь String, так как он приходит таким из API Дашборда
    private func statusColor(_ status: String) -> Color {
        switch status.lowercased() {
        case "approved": return .green
        case "rejected": return .red
        case "pending": return .orange
        case "created": return .blue
        default: return .gray
        }
    }
    
    private func formatStatus(_ status: String) -> String {
        switch status.lowercased() {
        case "approved": return "Одобрено"
        case "rejected": return "Отклонено"
        case "pending": return "В обработке"
        case "created": return "Создано"
        default: return status.uppercased()
        }
    }
}

struct LeaderboardCard: View {
    let leaderboard: [LeaderboardUser]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Рейтинг")
                .font(.headline)
            
            VStack(spacing: 0) {
                ForEach(Array(leaderboard.enumerated()), id: \.element.id) { index, user in
                    NavigationLink(destination: DashboardView(userId: user.id, isAdmin: false, title: "Статистика сотрудника")) {
                        HStack {
                            Text("\(index + 1)").bold().frame(width: 20)
                                .foregroundColor(index < 3 ? .orange : .secondary)
                            Text(user.fullName).font(.subheadline)
                                .foregroundColor(.primary)
                            Spacer()
                            Text("\(String(format: "%.1f", user.qualityScore))%").font(.caption).bold()
                                .foregroundColor(.blue)
                            Image(systemName: "chevron.right").font(.caption2).foregroundColor(.gray)
                        }
                        .padding(.vertical, 10)
                    }
                    if index < leaderboard.count - 1 { Divider() }
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(15)
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(10)
        .shadow(color: .gray.opacity(0.2), radius: 3)
    }
}

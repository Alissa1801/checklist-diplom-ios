import SwiftUI
import Charts
import SwiftUI
import Combine

struct DashboardView: View {
    @StateObject private var viewModel = DashboardViewModel()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    if viewModel.isLoading {
                        ProgressView("Загрузка статистики...")
                            .frame(height: 300)
                    } else if let error = viewModel.errorMessage {
                        VStack {
                            Image(systemName: "chart.line.downtrend.xyaxis")
                                .font(.largeTitle)
                                .foregroundColor(.orange)
                            Text(error)
                                .foregroundColor(.red)
                                .padding()
                            Button("Повторить") {
                                Task {
                                    await viewModel.fetchStats()
                                }
                            }
                        }
                        .frame(height: 300)
                    } else if let stats = viewModel.stats {
                        // Общая статистика
                        OverviewCard(stats: stats.stats.overview)
                        
                        // Качество
                        QualityCard(stats: stats.stats.quality)
                        
                        // Пользователи
                        UsersCard(stats: stats.stats.users)
                        
                        // Последние проверки
                        RecentChecksCard(checks: stats.stats.recentChecks)
                    }
                }
                .padding()
            }
            .navigationTitle("Статистика")
            .refreshable {
                await viewModel.fetchStats()
            }
        }
        .onAppear {
            Task {
                await viewModel.fetchStats()
            }
        }
    }
}

struct OverviewCard: View {
    let stats: DashboardStats.OverviewStats
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Общая статистика")
                .font(.headline)
            
            HStack(spacing: 15) {
                StatCard(
                    title: "Всего",
                    value: "\(stats.totalChecks)",
                    icon: "list.bullet",
                    color: .blue
                )
                
                StatCard(
                    title: "Одобрено",
                    value: "\(stats.approved)",
                    icon: "checkmark.circle.fill",
                    color: .green
                )
                
                StatCard(
                    title: "В работе",
                    value: "\(stats.pending)",
                    icon: "clock.fill",
                    color: .orange
                )
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
            .padding(.top, 5)
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
            Text("Качество работы")
                .font(.headline)
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Средняя оценка")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("\(String(format: "%.1f", stats.averageScore))%")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(stats.averageScore > 90 ? .green : .orange)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Проверок с фото")
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
            Text("Пользователи")
                .font(.headline)
            
            HStack(spacing: 15) {
                StatCard(
                    title: "Всего",
                    value: "\(stats.totalUsers)",
                    icon: "person.2.fill",
                    color: .purple
                )
                
                StatCard(
                    title: "Активных",
                    value: "\(stats.activeUsers)",
                    icon: "person.fill.checkmark",
                    color: .green
                )
            }
            
            HStack {
                Text("Проверок на пользователя:")
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(String(format: "%.1f", stats.checksPerUser))")
                    .font(.title2)
                    .fontWeight(.medium)
            }
        }
        .padding()
        .background(Color.purple.opacity(0.1))
        .cornerRadius(15)
    }
}

struct RecentChecksCard: View {
    let checks: [DashboardStats.RecentCheck]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Последние проверки")
                .font(.headline)
            
            if checks.isEmpty {
                Text("Нет последних проверок")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
            } else {
                ForEach(checks.prefix(3)) { check in
                    RecentCheckRow(check: check)
                }
                
                if checks.count > 3 {
                    NavigationLink(destination: AllRecentChecksView(checks: checks)) {
                        HStack {
                            Spacer()
                            Text("Показать все (\(checks.count))")
                                .font(.subheadline)
                                .foregroundColor(.blue)
                            Spacer()
                        }
                        .padding(.top, 5)
                    }
                }
            }
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(15)
    }
}

struct RecentCheckRow: View {
    let check: DashboardStats.RecentCheck
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(check.zoneName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(check.userName)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(check.status)
                    .font(.caption)
                    .fontWeight(check.status == "approved" ? .bold : .regular)
                    .foregroundColor(check.status == "approved" ? .green : .red)
                
                if let score = check.score {
                    Text("\(Int(score))%")
                        .font(.caption2)
                        .foregroundColor(.blue)
                }
            }
        }
        .padding(.vertical, 8)
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
        .background(Color.white)
        .cornerRadius(10)
        .shadow(color: .gray.opacity(0.2), radius: 3)
    }
}

struct AllRecentChecksView: View {
    let checks: [DashboardStats.RecentCheck]
    
    var body: some View {
        List(checks) { check in
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(check.zoneName)
                        .font(.headline)
                    Spacer()
                    Text(check.status)
                        .font(.caption)
                        .fontWeight(check.status == "approved" ? .bold : .regular)
                        .foregroundColor(check.status == "approved" ? .green : .red)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(check.status == "approved" ? Color.green.opacity(0.2) : Color.red.opacity(0.2))
                        .cornerRadius(4)
                }
                
                Text(check.userName)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack {
                    if let score = check.score {
                        Text("Оценка: \(Int(score))%")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                    
                    if let confidence = check.confidence {
                        Text("Уверенность: \(Int(confidence))%")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                    
                    Spacer()
                    
                    Text(formatDate(check.submittedAt))
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                if let feedback = check.feedback {
                    Text(feedback)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                }
            }
            .padding(.vertical, 8)
        }
        .navigationTitle("Последние проверки")
    }
    
    private func formatDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        if let date = formatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .short
            displayFormatter.timeStyle = .short
            return displayFormatter.string(from: date)
        }
        return dateString
    }
}

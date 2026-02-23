// Views/ChecksHistoryView.swift
import SwiftUI

struct ChecksHistoryView: View {
    @StateObject private var viewModel = ChecksViewModel()
    @State private var selectedCheck: Check?
    
    var body: some View {
        NavigationView {
            Group {
                if viewModel.isLoading {
                    ProgressView("Загрузка истории...")
                } else if let error = viewModel.errorMessage {
                    VStack {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundColor(.orange)
                        Text(error)
                            .foregroundColor(.red)
                            .padding()
                        Button("Повторить") {
                            Task {
                                await viewModel.fetchChecks()
                            }
                        }
                    }
                } else if viewModel.checks.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("История проверок пуста")
                            .font(.headline)
                        Text("Создайте первую проверку")
                            .foregroundColor(.secondary)
                    }
                } else {
                    List(viewModel.checks) { check in
                        NavigationLink(destination: CheckDetailView(check: check)) {
                            CheckRowView(check: check)
                        }
                    }
                }
            }
            .navigationTitle("История проверок")
            .refreshable {
                await viewModel.fetchChecks()
            }
        }
        .onAppear {
            Task {
                await viewModel.fetchChecks()
            }
        }
    }
}

struct CheckRowView: View {
    let check: Check
    
    var body: some View {
        HStack {
            // Иконка статуса
            Image(systemName: statusIcon)
                .font(.title2)
                .foregroundColor(statusColor)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(check.zone?.name ?? "Неизвестная зона")
                    .font(.headline)
                
                if let room = check.roomNumber, !room.isEmpty {
                    Text("• №\(room)")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                }
                
                Text(check.statusText)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if let score = check.score {
                    Text("Оценка: \(Int(score))%")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            
            Spacer()
            
            Text(formatDate(check.submittedAt))
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding(.vertical, 8)
    }
    
    private var statusIcon: String {
        switch check.status {
        case 0: return "clock.circle.fill"
        case 1: return "hourglass.circle.fill"
        case 2: return "checkmark.circle.fill"
        case 3: return "xmark.circle.fill"
        default: return "questionmark.circle.fill"
        }
    }
    
    private var statusColor: Color {
        switch check.status {
        case 0: return .orange
        case 1: return .blue
        case 2: return .green
        case 3: return .red
        default: return .gray
        }
    }
    
    private func formatDate(_ dateString: String) -> String {
        let isoFormatter = ISO8601DateFormatter()
        // Включаем поддержку миллисекунд, которые шлет Rails (.995Z)
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        // Пытаемся распарсить дату (сначала с миллисекундами, потом без)
        let date = isoFormatter.date(from: dateString) ?? ISO8601DateFormatter().date(from: dateString)
        
        guard let date = date else { return dateString }
        
        let displayFormatter = DateFormatter()
        displayFormatter.locale = Locale(identifier: "ru_RU")
        // Строгий формат: День.Месяц.Год, Часы:Минуты
        displayFormatter.dateFormat = "dd.MM.yyyy, HH:mm"
        
        return displayFormatter.string(from: date)
    }
}

struct CheckDetailView: View {
    let check: Check
    
    // Вычисляемые свойства для статуса
    private var statusIcon: String {
        switch check.status {
        case 0: return "clock.circle.fill"           // Создана
        case 1: return "hourglass.circle.fill"       // В обработке
        case 2: return "checkmark.circle.fill"       // Одобрена
        case 3: return "xmark.circle.fill"           // Отклонена
        default: return "questionmark.circle.fill"   // Неизвестно
        }
    }
    
    private var statusColor: Color {
        switch check.status {
        case 0: return .orange                       // Создана
        case 1: return .blue                         // В обработке
        case 2: return .green                        // Одобрена
        case 3: return .red                          // Отклонена
        default: return .gray                        // Неизвестно
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Заголовок
                VStack(alignment: .leading, spacing: 10) {
                    Text(check.zone?.name ?? "Неизвестная зона")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    if let room = check.roomNumber, !room.isEmpty {
                        Text("№\(room)")
                            .font(.title)
                            .foregroundColor(.blue)
                    }
                                        
                    HStack {
                        Image(systemName: statusIcon)
                            .foregroundColor(statusColor)
                        Text(check.statusText)
                            .font(.headline)
                    }
                }
                
                // Детали
                VStack(alignment: .leading, spacing: 10) {
                    Text("Детали проверки")
                        .font(.headline)
                    
                    if let room = check.roomNumber, !room.isEmpty {
                        DetailRow(title: "Номер комнаты", value: "№ \(room)")
                    }
                    
                    DetailRow(title: "Дата отправки", value: formatDate(check.submittedAt))
                    DetailRow(title: "Статус", value: check.statusText)
                    
                    if let score = check.score {
                        DetailRow(title: "Оценка", value: "\(Int(score))%")
                    }
                    
                    if let notes = check.notes, !notes.isEmpty {
                        DetailRow(title: "Заметки", value: notes)
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                
                // Анализ нейросети
                if let analysis = check.analysisResult {
                    AnalysisView(analysis: analysis)
                } else {
                    Text("Анализ еще не выполнен")
                        .foregroundColor(.secondary)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(10)
                }
                
                Spacer()
            }
            .padding()
        }
        .navigationTitle("Детали проверки")
    }
    
    private func formatDate(_ dateString: String) -> String {
        let isoFormatter = ISO8601DateFormatter()
        // Включаем поддержку миллисекунд, которые шлет Rails (.995Z)
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        // Пытаемся распарсить дату (сначала с миллисекундами, потом без)
        let date = isoFormatter.date(from: dateString) ?? ISO8601DateFormatter().date(from: dateString)
        
        guard let date = date else { return dateString }
        
        let displayFormatter = DateFormatter()
        displayFormatter.locale = Locale(identifier: "ru_RU")
        // Строгий формат: День.Месяц.Год, Часы:Минуты
        displayFormatter.dateFormat = "dd.MM.yyyy, HH:mm"
        
        return displayFormatter.string(from: date)
    }
}

struct DetailRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
        .padding(.vertical, 2)
    }
}

struct AnalysisView: View {
    let analysis: AnalysisResult
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Результат анализа нейросети")
                .font(.headline)
            
            VStack(spacing: 10) {
                HStack {
                    Image(systemName: analysis.isApproved == true ? "checkmark.shield.fill" : "xmark.shield.fill")
                        .font(.title)
                        .foregroundColor(analysis.isApproved == true ? .green : .red)
                    
                    VStack(alignment: .leading) {
                        Text(analysis.approvedText)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        if let confidence = analysis.confidenceScore {
                            Text("Уверенность: \(analysis.confidencePercentage)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                }
                
                // Детектированные объекты
                if let objects = analysis.detectedObjects, !objects.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Обнаружено:")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        ForEach(objects.indices, id: \.self) { index in
                            HStack {
                                Image(systemName: "checkmark.circle")
                                    .foregroundColor(.green)
                                    .font(.caption)
                                Text("\(objects[index].name) × \(objects[index].count)")
                                    .font(.caption)
                                Spacer()
                                Text("\(Int(objects[index].confidence * 100))%")
                                    .font(.caption2)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .padding()
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(8)
                }
                
                // Проблемы
                if let issues = analysis.issues, !issues.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Проблемы:")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        ForEach(issues.indices, id: \.self) { index in
                            HStack {
                                Image(systemName: "exclamationmark.triangle")
                                    .foregroundColor(.orange)
                                    .font(.caption)
                                Text(issues[index])
                                    .font(.caption)
                                Spacer()
                            }
                        }
                    }
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(8)
                }
                
                // Обратная связь
                if let feedback = analysis.feedback {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Обратная связь:")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Text(feedback)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
}

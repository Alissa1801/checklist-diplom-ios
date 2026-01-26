// Views/CheckResultView.swift
import SwiftUI

struct CheckResultView: View {
    let check: Check
    
    // Вычисляем иконку в зависимости от статуса
    private var statusIcon: String {
        switch check.status {
        case 0: return "clock.circle.fill"           // Создана
        case 1: return "hourglass.circle.fill"       // В обработке
        case 2: return "checkmark.circle.fill"       // Одобрена
        case 3: return "xmark.circle.fill"           // Отклонена
        default: return "questionmark.circle.fill"   // Неизвестно
        }
    }
    
    // Вычисляем цвет в зависимости от статуса
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
            VStack(spacing: 20) {
                // Статус
                VStack {
                    Image(systemName: statusIcon)
                        .font(.system(size: 60))
                        .foregroundColor(statusColor)
                    
                    Text(check.statusText)
                        .font(.title)
                        .fontWeight(.bold)
                    
                    if let score = check.score {
                        Text("Оценка: \(Int(score))%")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                
                // Анализ
                if let analysis = check.analysisResult {
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Анализ нейросети")
                            .font(.headline)
                        
                        // Детектированные объекты
                        if let objects = analysis.detectedObjects, !objects.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Обнаруженные предметы:")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                
                                ForEach(objects.indices, id: \.self) { index in
                                    HStack {
                                        Image(systemName: "checkmark.circle")
                                            .foregroundColor(.green)
                                        Text("\(objects[index].name) × \(objects[index].count)")
                                        Spacer()
                                        Text("\(Int(objects[index].confidence * 100))%")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                }
                            }
                        }
                        
                        // Проблемы
                        if let issues = analysis.issues, !issues.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Выявленные проблемы:")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                
                                ForEach(issues.indices, id: \.self) { index in
                                    HStack {
                                        Image(systemName: "exclamationmark.triangle")
                                            .foregroundColor(.orange)
                                        Text(issues[index])
                                        Spacer()
                                    }
                                }
                            }
                        }
                        
                        // Обратная связь
                        if let feedback = analysis.feedback {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Обратная связь:")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                
                                Text(feedback)
                                    .font(.body)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
                }
                
                Spacer()
            }
            .padding()
        }
        .navigationTitle("Результат проверки")
    }
}

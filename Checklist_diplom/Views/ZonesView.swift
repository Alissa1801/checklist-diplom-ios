import SwiftUI
import Combine

struct ZonesView: View {
    @StateObject private var viewModel = ZonesViewModel()
    
    var body: some View {
        NavigationView {
            Group {
                if viewModel.isLoading {
                    ProgressView("Загрузка зон...")
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
                                await viewModel.fetchZones()
                            }
                        }
                    }
                } else {
                    List(viewModel.zones) { zone in
                        NavigationLink(destination: ZoneDetailView(zone: zone)) {
                            VStack(alignment: .leading, spacing: 5) {
                                Text(zone.name)
                                    .font(.headline)
                                Text(zone.description)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                    .lineLimit(2)
                            }
                            .padding(.vertical, 5)
                        }
                    }
                }
            }
            .navigationTitle("Зоны уборки")
            .refreshable {
                await viewModel.fetchZones()
            }
        }
        .onAppear {
            Task {
                await viewModel.fetchZones()
            }
        }
    }
}

struct ZoneDetailView: View {
    let zone: Zone
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Заголовок
                VStack(alignment: .leading, spacing: 10) {
                    Text(zone.name)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text(zone.description)
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .padding(.bottom)
                
                // Стандартные предметы
                if let objects = zone.standardObjects, !objects.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Стандартные предметы")
                            .font(.headline)
                        
                        ForEach(objects.indices, id: \.self) { index in
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("\(objects[index].name) × \(objects[index].count)")
                                Spacer()
                            }
                            .padding(.vertical, 2)
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
                }
                
                // Пункты чек-листа
                if let points = zone.checklistPoints, !points.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Критерии проверки")
                            .font(.headline)
                        
                        ForEach(points.indices, id: \.self) { index in
                            HStack(alignment: .top) {
                                Text("\(index + 1).")
                                    .fontWeight(.medium)
                                Text(points[index])
                                Spacer()
                            }
                            .padding(.vertical, 5)
                        }
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(10)
                }
                
                Spacer()
            }
            .padding()
        }
        .navigationTitle(zone.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

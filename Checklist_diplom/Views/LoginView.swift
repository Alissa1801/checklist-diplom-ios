import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var email = "admin@example.com"
    @State private var password = "password"
    @State private var showingError = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Spacer()
                
                // Логотип
                Image(systemName: "checklist")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                
                Text("Цифровой чек-лист")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Система контроля качества уборки")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                Spacer()
                
                // Форма входа
                VStack(spacing: 15) {
                    TextField("Email", text: $email)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocapitalization(.none)
                        .keyboardType(.emailAddress)
                    
                    SecureField("Пароль", text: $password)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    if authViewModel.isLoading {
                        ProgressView()
                            .padding()
                    } else {
                        Button(action: login) {
                            Text("Войти")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                    }
                }
                .padding(.horizontal, 30)
                
                Spacer()
                
                Text("Демо доступ:\nadmin@example.com / password")
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.gray)
                    .padding()
            }
            .padding()
            .alert("Ошибка", isPresented: $showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(authViewModel.errorMessage ?? "Неизвестная ошибка")
            }
        }
    }
    
    private func login() {
        Task {
            await authViewModel.login(email: email, password: password)
            if let error = authViewModel.errorMessage {
                showingError = true
            }
        }
    }
}

import SwiftUI

struct LoginView: View {
    @Environment(AuthManager.self) private var authManager
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showRegister = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [Color(red: 0.05, green: 0.05, blue: 0.15), Color(red: 0.1, green: 0.1, blue: 0.25)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 32) {
                        // Logo
                        VStack(spacing: 12) {
                            Image(systemName: "globe.europe.africa.fill")
                                .font(.system(size: 64))
                                .foregroundStyle(.red)
                                .shadow(color: .red.opacity(0.5), radius: 20)

                            Text("Conflux")
                                .font(.largeTitle.bold())
                                .foregroundStyle(.white)

                            Text("Global Conflict Monitor")
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.6))
                        }
                        .padding(.top, 60)

                        // Form
                        VStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 6) {
                                Label("Email", systemImage: "envelope")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.white.opacity(0.7))
                                TextField("you@example.com", text: $email)
                                    .keyboardType(.emailAddress)
                                    .textContentType(.emailAddress)
                                    .autocapitalization(.none)
                                    .padding()
                                    .background(.white.opacity(0.1))
                                    .cornerRadius(12)
                                    .foregroundStyle(.white)
                            }

                            VStack(alignment: .leading, spacing: 6) {
                                Label("Password", systemImage: "lock")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.white.opacity(0.7))
                                SecureField("Min 8 characters", text: $password)
                                    .textContentType(.password)
                                    .padding()
                                    .background(.white.opacity(0.1))
                                    .cornerRadius(12)
                                    .foregroundStyle(.white)
                            }

                            if let error = errorMessage {
                                HStack {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                    Text(error)
                                        .font(.caption)
                                }
                                .foregroundStyle(.red)
                                .padding(.horizontal)
                            }

                            Button {
                                Task { await login() }
                            } label: {
                                if isLoading {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Text("Sign In")
                                        .font(.headline)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.red)
                            .cornerRadius(12)
                            .foregroundStyle(.white)
                            .disabled(isLoading || email.isEmpty || password.isEmpty)
                            .opacity((isLoading || email.isEmpty || password.isEmpty) ? 0.6 : 1)
                        }
                        .padding(.horizontal, 24)

                        // Register link
                        Button {
                            showRegister = true
                        } label: {
                            HStack {
                                Text("Don't have an account?")
                                    .foregroundStyle(.white.opacity(0.6))
                                Text("Register")
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.red)
                            }
                            .font(.subheadline)
                        }

                        Spacer()
                    }
                }
            }
            .navigationDestination(isPresented: $showRegister) {
                RegisterView()
            }
        }
    }

    private func login() async {
        isLoading = true
        errorMessage = nil
        do {
            let result = try await APIService.shared.login(email: email, password: password)
            authManager.saveToken(result.accessToken)
            await authManager.fetchCurrentUser()
        } catch let error as ServiceError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}

#Preview {
    LoginView()
        .environment(AuthManager())
}

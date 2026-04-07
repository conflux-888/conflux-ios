import SwiftUI

struct RegisterView: View {
    @Environment(AuthManager.self) private var authManager
    @Environment(\.dismiss) private var dismiss

    @State private var displayName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    var passwordsMatch: Bool { password == confirmPassword }
    var formValid: Bool { !displayName.isEmpty && !email.isEmpty && password.count >= 8 && passwordsMatch }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.05, green: 0.05, blue: 0.15), Color(red: 0.1, green: 0.1, blue: 0.25)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    VStack(spacing: 8) {
                        Text("Create Account")
                            .font(.largeTitle.bold())
                            .foregroundStyle(.white)
                        Text("Join the global conflict monitoring network")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.6))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 40)

                    VStack(spacing: 14) {
                        FormField(label: "Display Name", icon: "person", placeholder: "Your name", text: $displayName)
                        FormField(label: "Email", icon: "envelope", placeholder: "you@example.com", text: $email, keyboardType: .emailAddress)
                        FormField(label: "Password", icon: "lock", placeholder: "Min 8 characters", text: $password, isSecure: true)

                        VStack(alignment: .leading, spacing: 6) {
                            Label("Confirm Password", systemImage: "lock.shield")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.white.opacity(0.7))
                            SecureField("Re-enter password", text: $confirmPassword)
                                .textContentType(.newPassword)
                                .padding()
                                .background(.white.opacity(0.1))
                                .cornerRadius(12)
                                .foregroundStyle(.white)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(!confirmPassword.isEmpty && !passwordsMatch ? Color.red : Color.clear, lineWidth: 1)
                                )
                        }

                        if !confirmPassword.isEmpty && !passwordsMatch {
                            Text("Passwords do not match")
                                .font(.caption)
                                .foregroundStyle(.red)
                        }

                        if let error = errorMessage {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                Text(error)
                                    .font(.caption)
                            }
                            .foregroundStyle(.red)
                        }

                        Button {
                            Task { await register() }
                        } label: {
                            if isLoading {
                                ProgressView().tint(.white)
                            } else {
                                Text("Create Account")
                                    .font(.headline)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.red)
                        .cornerRadius(12)
                        .foregroundStyle(.white)
                        .disabled(isLoading || !formValid)
                        .opacity(isLoading || !formValid ? 0.6 : 1)
                    }
                    .padding(.horizontal, 24)

                    Button("Already have an account? Sign In") {
                        dismiss()
                    }
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.6))
                }
            }
        }
        .navigationBarBackButtonHidden()
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .foregroundStyle(.white)
                }
            }
        }
    }

    private func register() async {
        isLoading = true
        errorMessage = nil
        do {
            _ = try await APIService.shared.register(email: email, password: password, displayName: displayName)
            let loginResult = try await APIService.shared.login(email: email, password: password)
            authManager.saveToken(loginResult.accessToken)
            await authManager.fetchCurrentUser()
        } catch let error as ServiceError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}

struct FormField: View {
    let label: String
    let icon: String
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    var isSecure: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(label, systemImage: icon)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.7))
            Group {
                if isSecure {
                    SecureField(placeholder, text: $text)
                        .textContentType(isSecure ? .newPassword : .none)
                } else {
                    TextField(placeholder, text: $text)
                        .keyboardType(keyboardType)
                        .autocapitalization(.none)
                        .textContentType(keyboardType == .emailAddress ? .emailAddress : .name)
                }
            }
            .padding()
            .background(.white.opacity(0.1))
            .cornerRadius(12)
            .foregroundStyle(.white)
        }
    }
}

#Preview {
    NavigationStack {
        RegisterView()
            .environment(AuthManager())
    }
}

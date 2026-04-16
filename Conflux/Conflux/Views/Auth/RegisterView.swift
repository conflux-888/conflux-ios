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
            Color.cxBackground
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    VStack(spacing: 8) {
                        Text("CREATE ACCOUNT")
                            .font(.cxHeading)
                            .foregroundStyle(.cxText)
                            .tracking(3)
                        Text("JOIN THE GLOBAL CONFLICT MONITORING NETWORK")
                            .font(.cxLabel)
                            .foregroundStyle(.cxTextSecondary)
                            .tracking(1.5)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 40)

                    VStack(spacing: 14) {
                        FormField(label: "DISPLAY NAME", icon: "person", placeholder: "Your name", text: $displayName)
                        FormField(label: "EMAIL", icon: "envelope", placeholder: "you@example.com", text: $email, keyboardType: .emailAddress)
                        FormField(label: "PASSWORD", icon: "lock", placeholder: "Min 8 characters", text: $password, isSecure: true)

                        VStack(alignment: .leading, spacing: 6) {
                            Label("CONFIRM PASSWORD", systemImage: "lock.shield")
                                .font(.cxLabel)
                                .foregroundStyle(.cxTextSecondary)
                                .tracking(1)
                            SecureField("Re-enter password", text: $confirmPassword)
                                .textContentType(.newPassword)
                                .padding()
                                .background(Color.cxSurface)
                                .foregroundStyle(.cxText)
                                .font(.system(.body, design: .monospaced))
                                .clipShape(RoundedRectangle(cornerRadius: CXConstants.cornerRadius))
                                .overlay(
                                    RoundedRectangle(cornerRadius: CXConstants.cornerRadius)
                                        .stroke(
                                            !confirmPassword.isEmpty && !passwordsMatch ? Color.cxCritical : Color.cxBorder,
                                            lineWidth: CXConstants.borderWidth
                                        )
                                )
                        }

                        if !confirmPassword.isEmpty && !passwordsMatch {
                            Text("Passwords do not match")
                                .font(.cxData)
                                .foregroundStyle(.cxCritical)
                        }

                        if let error = errorMessage {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                Text(error)
                                    .font(.cxData)
                            }
                            .foregroundStyle(.cxCritical)
                        }

                        Button {
                            Task { await register() }
                        } label: {
                            if isLoading {
                                ProgressView().tint(.black)
                            } else {
                                Text("CREATE ACCOUNT")
                                    .font(.cxTitle)
                                    .tracking(2)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.cxAccent)
                        .foregroundStyle(.black)
                        .clipShape(RoundedRectangle(cornerRadius: CXConstants.cornerRadius))
                        .cxGlow(.cxAccent, radius: 12)
                        .disabled(isLoading || !formValid)
                        .opacity(isLoading || !formValid ? 0.5 : 1)
                    }
                    .padding(.horizontal, 24)

                    Button("Already have an account? Sign In") {
                        dismiss()
                    }
                    .font(.cxData)
                    .foregroundStyle(.cxTextTertiary)
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
                        .foregroundStyle(.cxAccent)
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
                .font(.cxLabel)
                .foregroundStyle(.cxTextSecondary)
                .tracking(1)
            Group {
                if isSecure {
                    SecureField(placeholder, text: $text)
                        .textContentType(.newPassword)
                } else {
                    TextField(placeholder, text: $text)
                        .keyboardType(keyboardType)
                        .autocapitalization(.none)
                        .textContentType(keyboardType == .emailAddress ? .emailAddress : .name)
                }
            }
            .cxField()
        }
    }
}

#Preview {
    NavigationStack {
        RegisterView()
            .environment(AuthManager())
    }
}

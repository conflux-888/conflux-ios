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
                Color.cxBackground
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 32) {
                        // Logo
                        VStack(spacing: 12) {
                            Image(systemName: "globe.europe.africa")
                                .font(.system(size: 64, weight: .thin))
                                .foregroundStyle(.cxAccent)
                                .cxGlow(.cxAccent, radius: 20)

                            Text("CONFLUX")
                                .font(.cxHeading)
                                .foregroundStyle(.cxText)
                                .tracking(4)

                            Text("GLOBAL CONFLICT MONITOR")
                                .font(.cxLabel)
                                .foregroundStyle(.cxTextSecondary)
                                .tracking(2)
                        }
                        .padding(.top, 60)

                        // Form
                        VStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 6) {
                                Label("EMAIL", systemImage: "envelope")
                                    .font(.cxLabel)
                                    .foregroundStyle(.cxTextSecondary)
                                    .tracking(1)
                                TextField("you@example.com", text: $email)
                                    .keyboardType(.emailAddress)
                                    .textContentType(.emailAddress)
                                    .autocapitalization(.none)
                                    .cxField()
                            }

                            VStack(alignment: .leading, spacing: 6) {
                                Label("PASSWORD", systemImage: "lock")
                                    .font(.cxLabel)
                                    .foregroundStyle(.cxTextSecondary)
                                    .tracking(1)
                                SecureField("Min 8 characters", text: $password)
                                    .textContentType(.password)
                                    .cxField()
                            }

                            if let error = errorMessage {
                                HStack {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                    Text(error)
                                        .font(.cxData)
                                }
                                .foregroundStyle(.cxCritical)
                                .padding(.horizontal)
                            }

                            Button {
                                Task { await login() }
                            } label: {
                                if isLoading {
                                    ProgressView()
                                        .tint(.black)
                                } else {
                                    Text("SIGN IN")
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
                            .disabled(isLoading || email.isEmpty || password.isEmpty)
                            .opacity((isLoading || email.isEmpty || password.isEmpty) ? 0.5 : 1)
                        }
                        .padding(.horizontal, 24)

                        // Register link
                        Button {
                            showRegister = true
                        } label: {
                            HStack {
                                Text("Don't have an account?")
                                    .foregroundStyle(.cxTextTertiary)
                                Text("REGISTER")
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.cxAccent)
                            }
                            .font(.cxData)
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

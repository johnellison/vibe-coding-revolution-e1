//
//  AuthService.swift
//  VibeScaler
//

import Foundation
import AuthenticationServices

class AuthService: NSObject, ObservableObject {
    @Published var isAuthenticated: Bool = false
    @Published var currentUser: User?
    @Published var isLoading: Bool = false
    @Published var error: String?

    private var sessionToken: String? {
        get { UserDefaults.standard.string(forKey: "sessionToken") }
        set { UserDefaults.standard.set(newValue, forKey: "sessionToken") }
    }

    var userName: String {
        currentUser?.displayName ?? "Guest"
    }

    var userInitials: String {
        currentUser?.initials ?? "G"
    }

    override init() {
        super.init()
        checkExistingSession()
    }

    // MARK: - Session Management

    private func checkExistingSession() {
        if let token = sessionToken, let user = User.load() {
            self.currentUser = user
            self.isAuthenticated = true
            // Validate token with backend
            Task {
                await validateSession(token: token)
            }
        }
    }

    private func validateSession(token: String) async {
        // TODO: Call backend to validate session
        // For now, trust the local session
    }

    // MARK: - Apple Sign In

    func signInWithApple() {
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.email, .fullName]

        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.performRequests()

        isLoading = true
    }

    func signOut() {
        sessionToken = nil
        currentUser = nil
        isAuthenticated = false
        User.clear()
    }

    // MARK: - Backend Authentication

    private func authenticateWithBackend(identityToken: String, userId: String, email: String?) async throws {
        // TODO: Replace with actual backend URL
        let apiURL = URL(string: "https://vibescaler-api.workers.dev/api/auth/apple")!

        var request = URLRequest(url: apiURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "identityToken": identityToken,
            "userId": userId,
            "email": email ?? ""
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw AuthError.serverError
        }

        let authResponse = try JSONDecoder().decode(AuthResponse.self, from: data)

        await MainActor.run {
            self.sessionToken = authResponse.sessionToken
            self.currentUser = authResponse.user
            self.currentUser?.save()
            self.isAuthenticated = true
        }
    }
}

// MARK: - ASAuthorizationControllerDelegate

extension AuthService: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let identityTokenData = appleIDCredential.identityToken,
              let identityToken = String(data: identityTokenData, encoding: .utf8) else {
            isLoading = false
            error = "Failed to get Apple ID credentials"
            return
        }

        let userId = appleIDCredential.user
        let email = appleIDCredential.email

        Task {
            do {
                try await authenticateWithBackend(
                    identityToken: identityToken,
                    userId: userId,
                    email: email
                )
            } catch {
                await MainActor.run {
                    self.error = error.localizedDescription
                }
            }
            await MainActor.run {
                self.isLoading = false
            }
        }
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        isLoading = false
        self.error = error.localizedDescription
    }
}

// MARK: - Auth Types

enum AuthError: LocalizedError {
    case serverError
    case invalidCredentials
    case networkError

    var errorDescription: String? {
        switch self {
        case .serverError: return "Server error. Please try again."
        case .invalidCredentials: return "Invalid credentials."
        case .networkError: return "Network error. Check your connection."
        }
    }
}

struct AuthResponse: Codable {
    let sessionToken: String
    let user: User
}

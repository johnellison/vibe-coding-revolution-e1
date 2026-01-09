//
//  User.swift
//  VibeScaler
//

import Foundation

struct User: Codable, Identifiable {
    let id: String
    let email: String?
    let appleId: String
    let createdAt: Date
    var imageCredits: Int
    var videoSeconds: Int
    var isPro: Bool
    var subscriptionExpiry: Date?

    var displayName: String {
        email?.components(separatedBy: "@").first ?? "User"
    }

    var initials: String {
        let name = displayName
        let components = name.components(separatedBy: " ")
        if components.count > 1 {
            return String(components[0].prefix(1) + components[1].prefix(1)).uppercased()
        }
        return String(name.prefix(2)).uppercased()
    }

    var videoMinutes: Double {
        Double(videoSeconds) / 60.0
    }
}

// MARK: - User Defaults Keys

extension User {
    static let currentUserKey = "com.johnellison.vibescaler.currentUser"

    static func load() -> User? {
        guard let data = UserDefaults.standard.data(forKey: currentUserKey) else {
            return nil
        }
        return try? JSONDecoder().decode(User.self, from: data)
    }

    func save() {
        guard let data = try? JSONEncoder().encode(self) else { return }
        UserDefaults.standard.set(data, forKey: User.currentUserKey)
    }

    static func clear() {
        UserDefaults.standard.removeObject(forKey: currentUserKey)
    }
}

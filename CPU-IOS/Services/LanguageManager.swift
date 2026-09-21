import Foundation
import SwiftUI
import Combine

/// Các ngôn ngữ hỗ trợ trong ứng dụng
enum AppLanguage: String, CaseIterable, Identifiable {
    case vietnamese = "vi"
    case english = "en"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .vietnamese: return "Tiếng Việt"
        case .english: return "English"
        }
    }

    var shortCode: String {
        switch self {
        case .vietnamese: return "VI"
        case .english: return "EN"
        }
    }

    var flag: String {
        switch self {
        case .vietnamese: return "🇻🇳"
        case .english: return "🇺🇸"
        }
    }
}

/// Quản lý ngôn ngữ ứng dụng với lưu trữ bền vững
final class LanguageManager: ObservableObject {
    static let shared = LanguageManager()

    private let userDefaultsKey = "app_selected_language"

    @Published var currentLanguage: AppLanguage {
        didSet {
            UserDefaults.standard.set(currentLanguage.rawValue, forKey: userDefaultsKey)
        }
    }

    private init() {
        if let saved = UserDefaults.standard.string(forKey: userDefaultsKey),
           let lang = AppLanguage(rawValue: saved) {
            self.currentLanguage = lang
        } else {
            // Mặc định Tiếng Việt
            self.currentLanguage = .vietnamese
        }
    }

    func toggleLanguage() {
        withAnimation(.easeInOut(duration: 0.2)) {
            currentLanguage = (currentLanguage == .vietnamese) ? .english : .vietnamese
        }
    }

    func tr(_ vi: String, _ en: String) -> String {
        return currentLanguage == .vietnamese ? vi : en
    }
}

import Foundation
import UIKit

// MARK: - Error Types

enum KuruttoError: LocalizedError {
    // Audio Errors
    case audioPlaybackFailed(String)
    case speechSynthesisFailed(String)
    case audioSessionSetupFailed
    
    // Data Errors
    case dataLoadFailed(String)
    case dataSaveFailed(String)
    case coreDataError(String)
    
    // Game Errors
    case questionGenerationFailed
    case invalidGameState
    case sceneLoadFailed
    
    // Network Errors
    case networkUnavailable
    case serverError(Int)
    
    // Resource Errors
    case resourceNotFound(String)
    case memoryWarning
    
    var errorDescription: String? {
        switch self {
        case .audioPlaybackFailed(let file):
            return "音声ファイル '\(file)' の再生に失敗しました"
        case .speechSynthesisFailed(let text):
            return "音声合成に失敗しました: \(text)"
        case .audioSessionSetupFailed:
            return "音声システムの初期化に失敗しました"
        case .dataLoadFailed(let reason):
            return "データの読み込みに失敗しました: \(reason)"
        case .dataSaveFailed(let reason):
            return "データの保存に失敗しました: \(reason)"
        case .coreDataError(let detail):
            return "データベースエラー: \(detail)"
        case .questionGenerationFailed:
            return "問題の生成に失敗しました"
        case .invalidGameState:
            return "ゲームの状態が不正です"
        case .sceneLoadFailed:
            return "3Dシーンの読み込みに失敗しました"
        case .networkUnavailable:
            return "ネットワークに接続できません"
        case .serverError(let code):
            return "サーバーエラー (コード: \(code))"
        case .resourceNotFound(let name):
            return "リソース '\(name)' が見つかりません"
        case .memoryWarning:
            return "メモリ不足です"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .audioPlaybackFailed, .speechSynthesisFailed, .audioSessionSetupFailed:
            return "設定で音声をオフにするか、アプリを再起動してください"
        case .dataLoadFailed, .dataSaveFailed, .coreDataError:
            return "アプリを再起動してください。問題が続く場合は再インストールをお試しください"
        case .questionGenerationFailed, .invalidGameState:
            return "メニューに戻ってゲームを再開してください"
        case .sceneLoadFailed:
            return "アプリを再起動してください"
        case .networkUnavailable:
            return "インターネット接続を確認してください"
        case .serverError:
            return "しばらく待ってから再度お試しください"
        case .resourceNotFound:
            return "アプリを再インストールしてください"
        case .memoryWarning:
            return "他のアプリを終了してからお試しください"
        }
    }
    
    var isRecoverable: Bool {
        switch self {
        case .audioPlaybackFailed, .speechSynthesisFailed, .audioSessionSetupFailed:
            return true  // Can continue without audio
        case .questionGenerationFailed, .networkUnavailable:
            return true  // Can retry
        case .dataLoadFailed, .dataSaveFailed, .coreDataError:
            return false  // Critical errors
        case .invalidGameState, .sceneLoadFailed:
            return false  // Need restart
        case .serverError:
            return true  // Can retry
        case .resourceNotFound:
            return false  // Critical error
        case .memoryWarning:
            return true  // Can try to free memory
        }
    }
}

// MARK: - Error Handler

class ErrorHandler {
    static let shared = ErrorHandler()
    
    private var errorLog: [ErrorLogEntry] = []
    private let maxLogEntries = 100
    
    private init() {}
    
    // MARK: - Error Handling
    
    func handle(_ error: Error, in viewController: UIViewController? = nil, recovery: (() -> Void)? = nil) {
        // Log the error
        logError(error)
        
        // Determine if it's a Kurutto error
        if let kuruttoError = error as? KuruttoError {
            handleKuruttoError(kuruttoError, in: viewController, recovery: recovery)
        } else {
            handleGenericError(error, in: viewController)
        }
    }
    
    private func handleKuruttoError(_ error: KuruttoError, in viewController: UIViewController?, recovery: (() -> Void)?) {
        // Special handling for specific errors
        switch error {
        case .memoryWarning:
            MemoryManager.shared.logMemoryUsage()
            // Try to free memory
            NotificationCenter.default.post(name: UIApplication.didReceiveMemoryWarningNotification, object: nil)
            
        case .audioPlaybackFailed, .speechSynthesisFailed:
            // Disable audio temporarily
            UserDefaults.standard.set(false, forKey: "soundEnabled")
            
        default:
            break
        }
        
        // Show user-friendly error if needed
        if error.isRecoverable {
            showRecoverableError(error, in: viewController, recovery: recovery)
        } else {
            showCriticalError(error, in: viewController)
        }
    }
    
    private func handleGenericError(_ error: Error, in viewController: UIViewController?) {
        let kuruttoError = KuruttoError.dataLoadFailed(error.localizedDescription)
        showRecoverableError(kuruttoError, in: viewController, recovery: nil)
    }
    
    // MARK: - UI Presentation
    
    private func showRecoverableError(_ error: KuruttoError, in viewController: UIViewController?, recovery: (() -> Void)?) {
        let alert = createChildFriendlyAlert(
            title: "あれれ？",
            message: simplifyErrorMessage(error),
            icon: "exclamationmark.triangle"
        )
        
        alert.addAction(UIAlertAction(title: "もういちど", style: .default) { _ in
            recovery?()
        })
        
        alert.addAction(UIAlertAction(title: "やめる", style: .cancel))
        
        present(alert, in: viewController)
    }
    
    private func showCriticalError(_ error: KuruttoError, in viewController: UIViewController?) {
        let alert = createChildFriendlyAlert(
            title: "こまったな...",
            message: simplifyErrorMessage(error),
            icon: "xmark.octagon"
        )
        
        alert.addAction(UIAlertAction(title: "メニューにもどる", style: .default) { _ in
            self.returnToMenu()
        })
        
        present(alert, in: viewController)
    }
    
    private func createChildFriendlyAlert(title: String, message: String, icon: String) -> UIAlertController {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        // Add custom styling for child-friendly appearance
        if let titleFont = UIFont(name: "HiraginoSans-W6", size: 24) {
            let titleAttributes = [NSAttributedString.Key.font: titleFont]
            let titleString = NSAttributedString(string: title, attributes: titleAttributes)
            alert.setValue(titleString, forKey: "attributedTitle")
        }
        
        if let messageFont = UIFont(name: "HiraginoSans-W3", size: 18) {
            let messageAttributes = [NSAttributedString.Key.font: messageFont]
            let messageString = NSAttributedString(string: message, attributes: messageAttributes)
            alert.setValue(messageString, forKey: "attributedMessage")
        }
        
        return alert
    }
    
    private func simplifyErrorMessage(_ error: KuruttoError) -> String {
        // Convert technical errors to child-friendly messages
        switch error {
        case .audioPlaybackFailed, .speechSynthesisFailed, .audioSessionSetupFailed:
            return "おとが ならないみたい。でも だいじょうぶ！ つづけられるよ。"
        case .questionGenerationFailed:
            return "もんだいが つくれなかった。もういちど やってみよう！"
        case .memoryWarning:
            return "ちょっと つかれちゃった。すこし やすもうね。"
        default:
            return "なにか うまくいかなかった。もういちど やってみよう！"
        }
    }
    
    private func present(_ alert: UIAlertController, in viewController: UIViewController?) {
        DispatchQueue.main.async {
            if let vc = viewController {
                vc.present(alert, animated: true)
            } else if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                      let rootVC = windowScene.windows.first?.rootViewController {
                rootVC.present(alert, animated: true)
            }
        }
    }
    
    private func returnToMenu() {
        NotificationCenter.default.post(name: .returnToMenu, object: nil)
    }
    
    // MARK: - Error Logging
    
    private func logError(_ error: Error) {
        let entry = ErrorLogEntry(
            timestamp: Date(),
            error: error,
            stackTrace: Thread.callStackSymbols
        )
        
        errorLog.append(entry)
        
        // Keep log size manageable
        if errorLog.count > maxLogEntries {
            errorLog.removeFirst()
        }
        
        // Log to console in debug
        #if DEBUG
        print("🚨 Error: \(error.localizedDescription)")
        print("📍 Stack trace:")
        Thread.callStackSymbols.prefix(10).forEach { print($0) }
        #endif
    }
    
    func getErrorLog() -> [ErrorLogEntry] {
        return errorLog
    }
    
    func clearErrorLog() {
        errorLog.removeAll()
    }
}

// MARK: - Error Log Entry

struct ErrorLogEntry {
    let timestamp: Date
    let error: Error
    let stackTrace: [String]
    
    var description: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .medium
        
        return """
        Time: \(formatter.string(from: timestamp))
        Error: \(error.localizedDescription)
        Stack: \(stackTrace.prefix(5).joined(separator: "\n"))
        """
    }
}

// MARK: - Global Error Handling

extension Notification.Name {
    static let returnToMenu = Notification.Name("returnToMenu")
}

// MARK: - Result Builder for Safe Operations

@resultBuilder
struct SafeOperationBuilder {
    static func buildBlock<T>(_ component: Result<T, Error>) -> Result<T, Error> {
        component
    }
}

func safely<T>(@SafeOperationBuilder operation: () throws -> T) -> Result<T, Error> {
    do {
        let result = try operation()
        return .success(result)
    } catch {
        ErrorHandler.shared.handle(error)
        return .failure(error)
    }
}
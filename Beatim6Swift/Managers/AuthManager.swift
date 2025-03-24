import MusicKit
import SwiftUI

@MainActor // 🎯 UI スレッドで動作するように明示
class AuthManager: ObservableObject {
    @Published var currentAuthStatus: MusicAuthorization.Status = MusicAuthorization.currentStatus
    
    // 認可されているかどうか（.authorized のとき true）
    var isAuthorized: Bool {
        currentAuthStatus == .authorized
    }
    
    /// 初回起動時などに呼び出して MusicKit の認証をリクエストする
    func requestMusicAuthorization() {
        Task {
            if currentAuthStatus == .notDetermined {
                let status = await MusicAuthorization.request()
                self.currentAuthStatus = status
            } else {
                // 現在の状態を保持
                self.currentAuthStatus = MusicAuthorization.currentStatus
            }
        }
    }

    /// 手動で現在の認可状態を再取得
    func reloadAuthStatus() {
        self.currentAuthStatus = MusicAuthorization.currentStatus
    }
}


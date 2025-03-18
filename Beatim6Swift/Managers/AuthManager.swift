import MusicKit
import SwiftUI

@MainActor // 🎯 UI スレッドで動作するように明示
class AuthManager: ObservableObject {
    @Published var currentAuthStatus: MusicAuthorization.Status = MusicAuthorization.currentStatus
    
    func requestMusicAuthorization() {
        Task {
            if currentAuthStatus == .notDetermined {
                let status = await MusicAuthorization.request()
                self.currentAuthStatus = status
            }
        }
    }
    
    func reloadAuthStatus() {
        self.currentAuthStatus = MusicAuthorization.currentStatus
    }
}


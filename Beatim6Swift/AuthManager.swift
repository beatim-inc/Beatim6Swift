import MusicKit
import SwiftUI

class AuthManager: ObservableObject {
    @Published var currentAuthStatus: MusicAuthorization.Status = MusicAuthorization.currentStatus
    
    func requestMusicAuthorization() {
        Task {
            if currentAuthStatus == .notDetermined { // 🎯 初回のみリクエスト
                let status = await MusicAuthorization.request()
                DispatchQueue.main.async {
                    self.currentAuthStatus = status
                }
            }
        }
    }
    
    func reloadAuthStatus() {
        DispatchQueue.main.async {
            self.currentAuthStatus = MusicAuthorization.currentStatus
        }
    }
}

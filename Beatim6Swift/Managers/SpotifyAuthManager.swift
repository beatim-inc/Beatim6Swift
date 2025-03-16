//
//  SpotifyAuthManager.swift
//  Beatim6Swift
//
//  Created by heilab on 2025-03-16.
//

import AuthenticationServices
import UIKit

class SpotifyAuthManager: NSObject, ASWebAuthenticationPresentationContextProviding {
    
    static let shared = SpotifyAuthManager()

    private var accessToken: String?
    
    // 🚀 Spotify 認証を開始する
    func startAuthorization(completion: @escaping (String?) -> Void) {
        let authURL = "https://accounts.spotify.com/authorize"
        let scopeEncoded = SpotifyAuth.scope.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        
        let urlString = "\(authURL)?client_id=\(SpotifyAuth.clientID)&response_type=code&redirect_uri=\(SpotifyAuth.redirectURI)&scope=\(scopeEncoded)"
        print("urlString: \(urlString)")
        
        guard let url = URL(string: urlString) else {
            completion(nil)
            return
        }

        let session = ASWebAuthenticationSession(url: url, callbackURLScheme: "\(SpotifyAuth.callbackURLScheme)") { callbackURL, error in
            guard let callbackURL = callbackURL, error == nil else {
                completion(nil)
                return
            }

            let queryItems = URLComponents(url: callbackURL, resolvingAgainstBaseURL: true)?.queryItems
            let code = queryItems?.first(where: { $0.name == "code" })?.value
            completion(code)
        }

        session.presentationContextProvider = self
        session.start()
    }
    
    // 🚀 `ASWebAuthenticationSession` の表示先を指定
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let keyWindow = windowScene.windows.first(where: { $0.isKeyWindow }) else {
            return UIWindow()
        }
        return keyWindow
    }
    
    // 🚀 認証コードをアクセストークンに交換
    func exchangeCodeForAccessToken(code: String, completion: @escaping (String?) -> Void) {
        let url = URL(string: "https://accounts.spotify.com/api/token")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        let bodyString = "grant_type=authorization_code&code=\(code)&redirect_uri=\(SpotifyAuth.redirectURI)&client_id=\(SpotifyAuth.clientID)&client_secret=\(SpotifyAuth.clientSecret)"
        request.httpBody = bodyString.data(using: .utf8)
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let task = URLSession.shared.dataTask(with: request) { data, _, error in
            guard let data = data, error == nil else {
                completion(nil)
                return
            }

            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let accessToken = json["access_token"] as? String {
                    self.accessToken = accessToken
                    print("✅ Spotify Access Token: \(accessToken)")
                    self.getSpotifyTokenInfo(accessToken: accessToken)
                    completion(accessToken)
                } else {
                    completion(nil)
                }
            } catch {
                completion(nil)
            }
        }

        task.resume()
    }
    
    // 🚀 `access_token` を取得
    func getAccessToken(completion: @escaping (String?) -> Void) {
        if let token = accessToken {
            completion(token)
        } else {
            startAuthorization { code in
                guard let code = code else {
                    completion(nil)
                    return
                }
                self.exchangeCodeForAccessToken(code: code, completion: completion)
            }
        }
    }
    
    private func getSpotifyTokenInfo(accessToken: String) {
        let urlString = "https://api.spotify.com/v1/me"

        guard let url = URL(string: urlString) else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print("🚨 Network error: \(error?.localizedDescription ?? "Unknown error")")
                return
            }

            if let jsonString = String(data: data, encoding: .utf8) {
                print("🔍 Spotify Token Info: \(jsonString)")
            }
        }

        task.resume()
    }
}

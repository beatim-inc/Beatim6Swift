import Foundation
import AuthenticationServices


import Foundation

// 🚀 Spotify で `trackID` を取得
func fetchTrackID(songName: String, artistName: String, completion: @escaping (String?) -> Void) {
    SpotifyAuthManager.shared.getAccessToken { accessToken in
        guard let accessToken = accessToken else {
            print("🚨 アクセストークンが取得できませんでした")
            completion(nil)
            return
        }

        let query = "\(songName) \(artistName)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "https://api.spotify.com/v1/search?q=\(query)&type=track&limit=1"

        guard let url = URL(string: urlString) else {
            completion(nil)
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        let task = URLSession.shared.dataTask(with: request) { data, _, error in
            guard let data = data, error == nil else {
                print("🚨 Network error: \(error?.localizedDescription ?? "Unknown error")")
                completion(nil)
                return
            }

            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let tracks = json["tracks"] as? [String: Any],
                   let items = tracks["items"] as? [[String: Any]],
                   let firstTrack = items.first,
                   let trackID = firstTrack["id"] as? String {
                    print("✅ Found Track ID: \(trackID)")
                    completion(trackID)
                } else {
                    print("🚨 トラック ID が見つかりませんでした")
                    completion(nil)
                }
            } catch {
                print("🚨 JSON デコードエラー: \(error.localizedDescription)")
                completion(nil)
            }
        }

        task.resume()
    }
}

// 🚀 `trackID` から BPM を取得
func fetchBPM(trackID: String, completion: @escaping (Double?) -> Void) {
    SpotifyAuthManager.shared.getAccessToken { accessToken in
        guard let accessToken = accessToken else {
            print("🚨 アクセストークンが取得できませんでした")
            completion(nil)
            return
        }
        
        let urlString = "https://api.spotify.com/v1/audio-features/\(trackID)"
        guard let url = URL(string: urlString) else {
            completion(nil)
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("🚨 Network error: \(error.localizedDescription)")
                completion(nil)
                return
            }

            guard let data = data else {
                print("🚨 No response data received")
                completion(nil)
                return
            }

            if let jsonString = String(data: data, encoding: .utf8) {
                print("🔍 Spotify Audio Features API Raw Response: \(jsonString)")
            }

            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    print("🔍 Parsed JSON: \(json)") // デバッグ用
                    if let bpm = json["tempo"] as? Double {
                        print("✅ Extracted BPM: \(bpm)")
                        completion(bpm)
                    } else {
                        print("🚨 `tempo` データが JSON に存在しません")
                        completion(nil)
                    }
                } else {
                    print("🚨 JSON パースエラー")
                    completion(nil)
                }
            } catch {
                print("🚨 JSON デコードエラー: \(error.localizedDescription)")
                completion(nil)
            }
        }
        
        task.resume()
    }
}

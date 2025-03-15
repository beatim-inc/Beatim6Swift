import Foundation

func fetchBPM(artist: String, album: String, song: String, completion: @escaping (String?) -> Void) {
    getSpotifyAccessToken { accessToken in
        guard let token = accessToken else {
            completion("Failed to get Spotify token")
            return
        }
        
        searchSpotifyTrack(artist: artist, song: song, accessToken: token) { trackID in
            guard let id = trackID else {
                completion("Track not found on Spotify")
                return
            }
            
            getSpotifyTrackBPM(trackID: id, accessToken: token) { bpm in
                if let bpmValue = bpm {
                    let formattedBPM = String(format: "%.1f BPM", bpmValue)
                    completion(formattedBPM)
                } else {
                    completion("BPM not found")
                }
            }
        }
    }
}

import AuthenticationServices

private func getSpotifyAccessToken(completion: @escaping (String?) -> Void) {
    let url = URL(string: "https://accounts.spotify.com/api/token")!
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    
    let credentials = "\(SpotifyAuth.clientID):\(SpotifyAuth.clientSecret)".data(using: .utf8)!.base64EncodedString()
    request.setValue("Basic \(credentials)", forHTTPHeaderField: "Authorization")
    request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
    
    let body = "grant_type=client_credentials"
    request.httpBody = body.data(using: .utf8)
    
    let task = URLSession.shared.dataTask(with: request) { data, _, error in
        guard let data = data, error == nil else {
            completion(nil)
            return
        }
        
        if let jsonString = String(data: data, encoding: .utf8) {
            print("🔍 Spotify OAuth Response: \(jsonString)")  // デバッグ用
        }
        
        do {
            if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
               let accessToken = json["access_token"] as? String {
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


private func searchSpotifyTrack(artist: String, song: String, accessToken: String, completion: @escaping (String?) -> Void) {
    let query = "\(song) \(artist)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
    let urlString = "https://api.spotify.com/v1/search?q=\(query)&type=track&limit=1"
    
    guard let url = URL(string: urlString) else {
        completion(nil)
        return
    }

    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
    
    let task = URLSession.shared.dataTask(with: request) { data, response, error in
        guard let data = data, error == nil else {
            print("🔍 Network error: \(error?.localizedDescription ?? "Unknown error")")  // デバッグ用
            completion(nil)
            return
        }

        if let jsonString = String(data: data, encoding: .utf8) {
            print("🔍 Spotify Search API Raw Response: \(jsonString)")
        }

        do {
            if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
               let tracks = json["tracks"] as? [String: Any],
               let items = tracks["items"] as? [[String: Any]],
               let firstItem = items.first,
               let trackID = firstItem["id"] as? String {
                print("🔍 Found Track ID: \(trackID)")  // デバッグ用
                completion(trackID)
            } else {
                completion(nil)
            }
        } catch {
            completion(nil)
        }
    }
    
    task.resume()
}


private func getSpotifyTrackBPM(trackID: String, accessToken: String, completion: @escaping (Double?) -> Void) {
    let urlString = "https://api.spotify.com/v1/audio-features/\(trackID)"
    
    guard let url = URL(string: urlString) else {
        completion(nil)
        return
    }

    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
    
    let task = URLSession.shared.dataTask(with: request) { data, response, error in
        guard let data = data, error == nil else {
            print("🔍 Network error: \(error?.localizedDescription ?? "Unknown error")")  // デバッグ用
            completion(nil)
            return
        }

        if let jsonString = String(data: data, encoding: .utf8) {
            print("🔍 Spotify Audio Features API Raw Response: \(jsonString)")
        }

        do {
            if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
               let bpm = json["tempo"] as? Double {
                print("🔍 Extracted BPM: \(bpm)")  // デバッグ用
                completion(bpm)
            } else {
                completion(nil)
            }
        } catch {
            completion(nil)
        }
    }
    
    task.resume()
}

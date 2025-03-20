//
//  BPMfetcher.swift
//  Beatim6Swift
//
//  Created by heilab on 2025-03-18.
//

import Foundation
import SwiftSoup

class BPMFetcher {
    let apiKey = "AIzaSyDu4RUh1JARrsU27LVcKdCHStJRSdJBdXY" // ✅ Google Custom Search APIキーをセット
    let cx = "675fbfdc2a9d5446e" // ✅ Google CSE IDをセット
    var historyManager: SongHistoryManager
    
    init(historyManager: SongHistoryManager) {
        self.historyManager = historyManager
    }

    /// Google Custom Search API を使ってSongBPMのURLを取得
    func searchSongBPM(song: String, artist: String, completion: @escaping (String?) -> Void) {
        let query = "\(song) \(artist) site:songbpm.com"
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "https://www.googleapis.com/customsearch/v1?q=\(encodedQuery)&key=\(apiKey)&cx=\(cx)"

        guard let url = URL(string: urlString) else {
            completion(nil)
            return
        }

        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                completion(nil)
                return
            }

            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let items = json["items"] as? [[String: Any]],
                   let firstItem = items.first,
                   let link = firstItem["link"] as? String {
                    completion(link)
                } else {
                    completion(nil)
                }
            } catch {
                completion(nil)
            }
        }
        task.resume()
    }

    /// 取得したページURLからBPMをスクレイピング
    func getBPM(from url: String, completion: @escaping (String?) -> Void) {
        guard let pageURL = URL(string: url) else {
            completion(nil)
            return
        }

        let task = URLSession.shared.dataTask(with: pageURL) { data, response, error in
            guard let data = data, error == nil,
                  let html = String(data: data, encoding: .utf8) else {
                completion(nil)
                return
            }

            do {
                let document = try SwiftSoup.parse(html)
                let bpmElements = try document.select("dd.mt-1.text-3xl.font-semibold.text-card-foreground")
                
                if bpmElements.size() >= 3 {
                    let bpm = try bpmElements.get(2).text()
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

    /// BPMを取得するメイン関数
    func fetchBPM(song: String, artist: String, id: String, completion: @escaping (Double?) -> Void) {
        // ✅ 既存の BPM を履歴から探す
        if let existingBPM = historyManager.getBPM(for: id) {
            print("✅ 履歴に BPM \(existingBPM) が見つかりました (ID: \(id))")
            completion(existingBPM) // 🎯 `Double?` をそのまま返す
            return
        }

        // 🛜 履歴にない場合、Web 検索を実行
        searchSongBPM(song: song, artist: artist) { songURL in
            guard let songURL = songURL else {
                completion(nil)
                return
            }
            self.getBPM(from: songURL) { fetchedBPM in
                if let bpmString = fetchedBPM, let bpmDouble = Double(bpmString) {
                    // ✅ 履歴に追加 (⚠️ ここがバックグラウンドスレッドの可能性あり)
                    DispatchQueue.main.async {
                        self.historyManager.addSong(id: id, bpm: bpmDouble) // ⚠️ ここをメインスレッドで実行
                    }
                    completion(bpmDouble)
                } else {
                    completion(nil)
                }
            }
        }
    }
}



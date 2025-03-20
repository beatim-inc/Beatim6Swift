//
//  SongHistoryManager.swift
//  Beatim6Swift
//
//  Created by heilab on 2025-03-20.
//

import SwiftUI

struct PlayedSong: Codable, Identifiable {
    var id: String  // 曲のID
    var bpm: Double // BPM
}

class SongHistoryManager: ObservableObject {
    @Published var playedSongs: [PlayedSong] = []
    private let fileName = "playedSongs.json"
    
    init() {
        loadHistory()
    }

    // 📌 履歴に曲を追加し、保存
    func addSong(id: String, bpm: Double) {
        if let index = playedSongs.firstIndex(where: { $0.id == id }) {
            // 🎯 すでに存在する場合は BPM を更新
            playedSongs[index].bpm = bpm
            print("✅ 既存の曲 (ID: \(id)) の BPM を更新しました")
        } else {
            // 🎯 存在しない場合は新しく追加
            let newSong = PlayedSong(id: id, bpm: bpm)
            playedSongs.append(newSong)
            print("✅ 新しい曲 (ID: \(id)) を履歴に追加しました")
        }

        // 🎯 100件以上になったら最古のデータを削除
        if playedSongs.count > 100 {
            playedSongs.removeFirst()
        }

        saveHistory() // 🎯 JSON に保存
    }
    
    func deleteSong(at offsets: IndexSet) {
        playedSongs.remove(atOffsets: offsets) // 🎯 指定されたインデックスを削除
        saveHistory() // 🎯 削除後に履歴を保存
    }

    // 📌 履歴を保存 (JSON 形式)
    private func saveHistory() {
        do {
            let data = try JSONEncoder().encode(playedSongs)
            let url = getFileURL()
            try data.write(to: url, options: .atomic)
            print("✅ 再生履歴を保存しました: \(url)")
        } catch {
            print("❌ 履歴の保存に失敗: \(error.localizedDescription)")
        }
    }

    // 📌 履歴を読み込む
    private func loadHistory() {
        let url = getFileURL()
        do {
            let data = try Data(contentsOf: url)
            let history = try JSONDecoder().decode([PlayedSong].self, from: data)
            self.playedSongs = history
            print("✅ 再生履歴を読み込みました")
        } catch {
            print("⚠️ 履歴の読み込みに失敗 (初回起動の可能性): \(error.localizedDescription)")
            self.playedSongs = []
        }
    }

    // 📌 ファイルの保存先を取得
    private func getFileURL() -> URL {
        let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documentDirectory.appendingPathComponent(fileName)
    }
}

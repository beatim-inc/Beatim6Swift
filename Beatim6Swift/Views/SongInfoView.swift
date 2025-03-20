//
//  PlayMusicView.swift
//  MusicKit_Demo
//
//  Created by Shunzhe on 2022/01/22.
//

import SwiftUI
import MusicKit

struct SongInfoView: View {
    var songItem: Song
    @Binding var currentArtistName: String?
    
    var body: some View {         
        // Music Player
        Button(action: {
            Task {
                let player = ApplicationMusicPlayer.shared
                await MainActor.run {
                    self.currentArtistName = songItem.artistName
                }
                // 🎯 キューを設定
                player.queue = .init(for: [songItem])

                // 🎯 再生 → すぐに一時停止
                do {
                    try await player.play()
                    try await Task.sleep(nanoseconds: 100_000_000) // 0.1秒待機
                    player.pause()
                } catch {
                    print("⚠️ エラー: \(error.localizedDescription)")
                }
            }
        }) {
            // Song info
            HStack(alignment: .center) {
                if let artwork = songItem.artwork {
                    ArtworkImage(artwork, height: 40)
                }
                VStack(alignment: .leading) {
                    Text(songItem.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text("\(songItem.artistName) \(songItem.albumTitle ?? "")")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
        }
    }
    
}

struct SongHistoryRowView: View {
    var songID: String
    @Binding var currentArtistName: String?
    @State private var songItem: Song?

    var body: some View {
        if let songItem = songItem {
            // ✅ `SongInfoView` を活用
            SongInfoView(songItem: songItem, currentArtistName: $currentArtistName)
        } else {
            // 🎯 Apple Music からデータ取得中のプレースホルダー
            HStack {
                ProgressView() // 🔄 読み込み中インジケーター
                Text("Loading...")
                    .foregroundColor(.gray)
            }
            .task {
                await loadSongItem()
            }
        }
    }

    // Apple Music から `SongItem` を取得
    private func loadSongItem() async {
        let song = await SongHistoryManager().fetchSongItem(for: songID)
        DispatchQueue.main.async {
            self.songItem = song
        }
    }
}

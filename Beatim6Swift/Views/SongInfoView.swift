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
//                    try await Task.sleep(nanoseconds: 100_000_000) // 0.1秒待機
//                    player.pause()
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
    @State private var isLoading: Bool = true
    @EnvironmentObject var songHistoryManager: SongHistoryManager

    var body: some View {
        HStack {
            if let songItem = songItem {
                SongInfoView(songItem: songItem, currentArtistName: $currentArtistName)
                
//                Spacer()
//                
//                // 🎼 BPM情報を追加
//                if let bpm = songHistoryManager.getBPM(for: songID) {
//                    Text("\(bpm, specifier: "%.1f") BPM")
//                        .foregroundColor(.secondary)
//                        .font(.subheadline)
//                } else {
//                    Text("BPM 未設定")
//                        .foregroundColor(.gray)
//                        .font(.subheadline)
//                }
            } else if isLoading {
                HStack {
                    ProgressView()
                    Text("Loading...")
                        .foregroundColor(.gray)
                }
                .onAppear {
                    Task {
                        await loadSongItem()
                    }
                }
            } else {
                Text("❌ 曲情報取得失敗")
                    .foregroundColor(.gray)
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

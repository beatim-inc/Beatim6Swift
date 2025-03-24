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
    @Binding var musicDefaultBpm: Double
    @Binding var bpmErrorMessage: String
    @EnvironmentObject var songHistoryManager: SongHistoryManager
    @EnvironmentObject var spmManager: SPMManager
    
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
                
                if let musicDefaultBpm = songHistoryManager.getBPM(for: songItem.id.rawValue) {
                    player.state.playbackRate = Float(spmManager.spm / musicDefaultBpm)        // ✅ BPM更新後に再生速度を変更
                    print("Updated BPM: \(musicDefaultBpm)")
                    bpmErrorMessage = ""
                } else {
                    print("Failed to fetch BPM")
                    bpmErrorMessage = "⚠️"
                    player.pause() // BPMを取得できなかったときは再生をとめる
                }

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
                    ArtworkImage(artwork, width: 40, height: 40)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
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
    
    /// 現在の曲名からBPMを取得
    private func fetchBPMForCurrentSong() {

        
    }
    
}

struct SongHistoryRowView: View {
    var songID: String
    @Binding var currentArtistName: String?
    @Binding var musicDefaultBpm: Double
    @Binding var bpmErrorMessage: String
    @State private var songItem: Song?
    @State private var isLoading: Bool = true
    @EnvironmentObject var songHistoryManager: SongHistoryManager
    @EnvironmentObject var spmManager: SPMManager

    var body: some View {
        HStack {
            if let songItem = songItem {
                SongInfoView(
                    songItem: songItem,
                    currentArtistName: $currentArtistName,
                    musicDefaultBpm: $musicDefaultBpm,
                    bpmErrorMessage: $bpmErrorMessage
                )
                    .environmentObject(songHistoryManager)
                    .environmentObject(spmManager)
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

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
    @Binding var autoPause: Bool
    @EnvironmentObject var songHistoryManager: SongHistoryManager
    @EnvironmentObject var spmManager: SPMManager
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {         
        // Music Player
        Button(action: {
            Task {
                guard authManager.isAuthorized else {
                    print("🚫 MusicKit authorization not granted.")
                    bpmErrorMessage = "🔒"
                    return
                }
                
                let player = ApplicationMusicPlayer.shared
                await MainActor.run {
                    self.currentArtistName = songItem.artistName
                }
                // 🎯 キューを設定
                player.queue = .init(for: [songItem])
                
                // 先に再生準備
                do {
                    try await player.prepareToPlay()
                } catch {
                    print("prepareToPlay failed: \(error)")
                    return
                }
                
                // BPMが取得できていれば playbackRate 設定
                if let bpm = songHistoryManager.getBPM(for: songItem.id.rawValue) {
                    print("✅️ BPM got from history: \(bpm)")
                    musicDefaultBpm = bpm
                    let rate = Float(spmManager.spm / bpm)
                    player.state.playbackRate = rate // 実質的にこの時点で曲の再生が開始する
                    print("設定した playbackRate: \(rate)")
                    bpmErrorMessage = ""
                    
                    // ⏸️ 自動一時停止処理
                    if autoPause {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 90) {
                            Task {
                                // 再生中であれば一時停止
                                if player.state.playbackStatus == .playing {
                                    player.pause()
                                    print("⏸️ 自動一時停止しました（90秒）")
                                }
                            }
                        }
                    }
                    
                } else {
                    bpmErrorMessage = "🔍"
                    player.pause()
                    return
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    print("再生後の playbackRate: \(player.state.playbackRate)")
                }
                
                // player.play() を実行すると再生速度が1に戻ってしまうので書かない

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
    
}

struct SongHistoryRowView: View {
    var songID: String
    @Binding var currentArtistName: String?
    @Binding var musicDefaultBpm: Double
    @Binding var bpmErrorMessage: String
    @Binding var autoPause: Bool
    @State private var songItem: Song?
    @State private var isLoading: Bool = true
    @EnvironmentObject var songHistoryManager: SongHistoryManager
    @EnvironmentObject var spmManager: SPMManager
    @EnvironmentObject var authManager: AuthManager

    var body: some View {
        HStack {
            if let songItem = songItem {
                SongInfoView(
                    songItem: songItem,
                    currentArtistName: $currentArtistName,
                    musicDefaultBpm: $musicDefaultBpm,
                    bpmErrorMessage: $bpmErrorMessage,
                    autoPause: $autoPause
                )
                    .environmentObject(songHistoryManager)
                    .environmentObject(spmManager)
                    .environmentObject(authManager)
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

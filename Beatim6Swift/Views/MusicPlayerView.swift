//
//  MusicPlayerView.swift
//  Beatim6Swift
//
//  Created by 野村健介 on 2025/03/01.
//

import Foundation
import SwiftUI
import MusicKit

struct MusicPlayerView: View {
    @State private var playbackProgress: Double = 0
    @State private var songDuration: Double = 0
    @State private var playbackTimer: Timer?
    @State private var isPlaying: Bool = false
    @State private var artworkURL: URL? // ジャケット画像のURL
    @Binding var songTitle: String
    @Binding var artistName: String? // アーティスト名
    @State private var albumTitle: String? // アルバム名
    @Binding var trackId: String? // id
    @Binding var bpmErrorMessage: String
    
    @StateObject var stepSoundManager: StepSoundManager
    @StateObject var spmManager: SPMManager
    @Binding var musicDefaultBpm: Double 
    @State private var songItem: MusicItem? // 再生する曲情報
    @State private var showBpmSetting = false
    @State private var showSpmSetting = false
    @EnvironmentObject var songHistoryManager: SongHistoryManager

    var body: some View {
        VStack {
            HStack (alignment: .center) {
                VStack {
                    HStack (spacing: 4) {
                        Image(systemName: "figure.walk")
                            .frame(width:24, height: 24)
                            .font(.system(size: 24, weight: .bold))
                        Text("\(String(format: "%.1f", spmManager.spm))")
                            .foregroundColor(.primary)
                            .frame(alignment: .trailing)
                    }
                    .frame(width: 150, height: 32)
                    Text("Walk Tempo")
                        .foregroundColor(.primary)
                        .font(.caption)
                }
                .onTapGesture {
                    showSpmSetting = true // ✅ タップ時にシートを開く
                }
                .sheet(isPresented: $showSpmSetting) { // ✅ `sheet` を使ってモーダル遷移
                    SpmSettingView(
                        spm: spmManager.spm,
                        onSpmUpdate: { newSpm in spmManager.spm = newSpm }
                    )
                    .presentationDetents([.height(80)])
                }
                .frame(height: 40)
            
                Spacer()

                VStack {
                    HStack (spacing: 10) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .frame(width:24, height: 24)
                            .font(.system(size: 24, weight: .bold))
                        Toggle(isOn: $spmManager.allowStepUpdate) {}
                            .labelsHidden()
                    }
                    .frame(width: 150, height: 32)
                    Text("Auto Tempo Update")
                        .foregroundColor(.primary)
                        .font(.caption)
                }
                .frame(height: 40)

            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            
            // シーケンスバー
            VStack(alignment: .leading){
                
                HStack {
                    Text(timeString(from: ApplicationMusicPlayer.shared.playbackTime))
                      .font(.caption)
                      .foregroundColor(.gray)
                    Spacer()
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            // 背景のグレーのバー
                            Rectangle()
                                .frame(height: 4)
                                .foregroundColor(Color.gray.opacity(0.5))
                                .cornerRadius(2)

                            // 再生済みの部分
                            Rectangle()
                                .frame(width: CGFloat(playbackProgress / max(songDuration, 1)) * geometry.size.width, height: 4)
                                .foregroundColor(.primary)
                                .cornerRadius(2)
                        }
                    }
                    .frame(height: 4)
                    .padding(.vertical, 5)
                    Spacer()
                    Text(timeString(from: songDuration - ApplicationMusicPlayer.shared.playbackTime))
                      .font(.caption)
                      .foregroundColor(.gray)
                }
            }
            .padding(.horizontal, 16) // 左右の余白を維持
            .padding(.top, 8) // 上の余白を維持
            
            //再生ボタン系
            
                
            HStack (spacing: 10){
                // 🎵 ジャケット画像
                if let url = artworkURL {
                    AsyncImage(url: url) { image in
                        image.resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 50, height: 50)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    } placeholder: {
                        Image(systemName: "music.note")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 50, height: 50)
                            .foregroundColor(.gray)
                    }
                }
                
                VStack(alignment: .leading) {
                    Text(songTitle)
                        .font(.headline)
                        .lineLimit(1)
                        .foregroundColor(.primary)
                    
                    // 🎵 アーティスト名（曲がある場合のみ表示）
                    if let artist = artistName {
                        Text("\(artist)")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                if (bpmErrorMessage == "") {
                    //頭出しボタン
                    Button(action:{
                        Task{
                            stepSoundManager.playSoundPeriodically(BPM:spmManager.spm)
                            ApplicationMusicPlayer.shared.playbackTime = 0
                            ApplicationMusicPlayer.shared.pause()
                        }
                    }
                    ) {
                        Image(systemName:"backward.fill")
                            .symbolRenderingMode(.hierarchical) // 視認性向上
                            .imageScale(.large) // アイコンのスケール調整
                            .font(.system(size: 24)) // アイコンのサイズ
                            .foregroundColor(.primary)
                            .frame(width: 44, height: 44) // タップ領域の確保
                    }
                    
                    // 再生・停止ボタン
                    Button(action: togglePlayback) {
                        Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                            .symbolRenderingMode(.hierarchical)
                            .imageScale(.large)
                            .font(.system(size: 24))
                            .foregroundColor(.primary)
                            .frame(width: 44, height: 44)
                    }
                }
                else {
                    HStack {
                        Text("⚠️ Tap here to set BPM manually")
                    }
                    .contentShape(Rectangle()) // ✅ タップ可能にする
                    .onTapGesture {
                        showBpmSetting = true // ✅ タップ時にシートを開く
                    }
                    .sheet(isPresented: $showBpmSetting) { // ✅ `sheet` を使ってモーダル遷移
                        BpmSettingView(
                            bpm: musicDefaultBpm,
                            trackId: trackId ?? "Unknown",
                            bpmErrorMessage: $bpmErrorMessage,
                            onBpmUpdate: { newBpm in musicDefaultBpm = newBpm }
                        )
                        .presentationDetents([.height(80)])
                        .environmentObject(songHistoryManager)
                    }
                    .padding(6)
                    .background(
                        RoundedRectangle(cornerRadius: 6) // ✅ 角丸の四角形
                            .fill(Color.gray.opacity(0.1))
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 16)
        }
        .onAppear {
            startPlaybackObserver()
        }
        .onDisappear {
            stopPlaybackObserver()
        }
            
    }

    /// Apple Music の再生状態を監視
    private func startPlaybackObserver() {
        playbackTimer?.invalidate()
        playbackTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            Task {
                let player = ApplicationMusicPlayer.shared
                let state = player.state
                let currentEntry = player.queue.currentEntry?.item

                await MainActor.run {
                    self.isPlaying = state.playbackStatus == .playing
                    self.playbackProgress = player.playbackTime

                    if let nowPlayingItem = currentEntry, case .song(let song) = nowPlayingItem {
                        // 🎵 再生中なら現在の曲を取得
                        self.songDuration = song.duration ?? 1
                        self.songTitle = song.title
                        self.albumTitle = song.albumTitle ?? ""
                        self.artworkURL = song.artwork?.url(width: 100, height: 100)
                        self.trackId = song.id.rawValue
                    } else {
                        self.songTitle = "Not Playing"
                        self.albumTitle = nil
                        self.artworkURL = nil
                        self.trackId = nil
                    }
                }
            }
        }
    }




    /// タイマー停止
    private func stopPlaybackObserver() {
        playbackTimer?.invalidate()
        playbackTimer = nil
    }

    /// 再生・停止の切り替え
    private func togglePlayback() {
        self.isPlaying = !self.isPlaying
        let player = ApplicationMusicPlayer.shared

        Task {
            if(player.state.playbackStatus == MusicPlayer.PlaybackStatus.playing ){
                player.pause()
                stepSoundManager.stopPeriodicSound()
                return;
            }
            do {
                try await player.prepareToPlay()
                stepSoundManager.playSoundPeriodically(BPM:spmManager.spm)
                //これを入れると再生速度が1になってしまう
                //try await ApplicationMusicPlayer.shared.play()
                player.state.playbackRate =
                (spmManager.spm > 0 ?
                Float(spmManager.spm/musicDefaultBpm) : 1.0)
                print(player.state.playbackRate)
                print(player.state.playbackStatus)
                await MainActor.run {
                    self.isPlaying = player.state.playbackStatus == .playing
                }
            } catch {
                print(error.localizedDescription)
            }
        }
    }
    // ⏳ "mm:ss" 形式に変換する関数
    private func timeString(from time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

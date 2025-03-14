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
    
    //NOTE:UI切り替え専用。ApplicationMusicPlayerの状態と必ずしも一致しない。
    @State private var isPlaying: Bool = false
    @State private var artworkURL: URL? // ジャケット画像のURL
    @State private var songTitle: String = "Not Playing"
    @State private var artistName: String? // アーティスト名
    @State private var albumTitle: String? // アルバム名
    
    @StateObject var stepSoundManager: StepSoundManager
    @StateObject var spmManager: SPMManager
    var musicDefaultBpm: Double 
    @State private var songItem: MusicItem? // 再生する曲情報

    var body: some View {
        VStack {
//            // 行動開始位置を示すアイコン系
//            HStack(spacing: 5) {
//                Spacer().frame(width :0)
//                //イントロ（立ち止まる）
//                VStack{
//                    Image(systemName: "figure.stand")
//                    .resizable()
//                    .frame(width: 20, height: 40)
//                    .foregroundColor(.gray)
//                    Color.gray.frame(width: 35,height: 5)
//                }
//                
//                //歌（歩く）
//                VStack{
//                    Image(systemName: "figure.walk")
//                    .resizable()
//                    .frame(width: 20, height: 40)
//                    .foregroundColor(.gray)
//                    Color.gray.frame(width: 90,height: 5)
//                }
//
//                //間奏（立ち止まる）
//                VStack{
//                    Image(systemName: "figure.stand")
//                    .resizable()
//                    .frame(width: 20, height: 40)
//                    .foregroundColor(.gray)
//                    Color.gray.frame(width: 35,height: 5)
//                }
//        
//                //試行終了（デバイスを外す）
//                /*
//                VStack{
//                    Image(systemName: "checkmark")
//                    .resizable()
//                    .frame(width: 20, height: 20)
//                    .foregroundColor(.gray)
//                }
//                */
//                Spacer()
//            }
            
            // シーケンスバー
            VStack(alignment: .leading){
                Slider(value: $playbackProgress, in: 0...songDuration)
                HStack {
                    Text(timeString(from: ApplicationMusicPlayer.shared.playbackTime))
                      .font(.caption)
                      .foregroundColor(.gray)
                    Spacer()
                    Text(timeString(from: songDuration - ApplicationMusicPlayer.shared.playbackTime))
                      .font(.caption)
                      .foregroundColor(.gray)
                }
            }
            .padding()
            
            //再生ボタン系
            HStack (spacing: 20){
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
                        .resizable()
                        .frame(width: 30, height: 30)
                        .foregroundColor(.gray)
                }
                Spacer().frame(width: 5)
                // 再生・停止ボタン
                Button(action: togglePlayback) {
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .resizable()
                        .frame(width: 30, height: 30)
                        .foregroundColor(.gray)
                }
                Spacer().frame(width: 5)
            }
            .padding()
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
                    print("\(player.queue.entries.count)")

                    if let nowPlayingItem = currentEntry, case .song(let song) = nowPlayingItem {
                        // 🎵 再生中なら現在の曲を取得
                        self.songDuration = song.duration ?? 1
                        self.songTitle = song.title
                        self.artistName = song.artistName
                        self.albumTitle = song.albumTitle ?? ""
                        self.artworkURL = song.artwork?.url(width: 100, height: 100)
                    } else {
                        self.songTitle = "Not Playing"
                        self.artistName = nil
                        self.albumTitle = nil
                        self.artworkURL = nil
                        print("Not Playing")
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

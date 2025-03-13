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
    @State private var songDuration: Double = 1
    @State private var playbackTimer: Timer?
    
    //NOTE:UI切り替え専用。ApplicationMusicPlayerの状態と必ずしも一致しない。
    @State private var isPlaying: Bool = false
    
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
                Text(timeString(from: ApplicationMusicPlayer.shared.playbackTime))
                      .font(.caption)
                      .foregroundColor(.gray)
            }
            .padding()
            
            //再生ボタン系
            HStack (spacing: 40){
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
                // 再生・停止ボタン
                Button(action: togglePlayback) {
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .resizable()
                        .frame(width: 30, height: 30)
                        .foregroundColor(.gray)
                }
                Spacer().frame(width: 30)
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

//                if state.playbackStatus == .playing, let queueEntry = player.queue.currentEntry?.item,
//                   case .song(let nowPlayingItem) = queueEntry {
//                    await MainActor.run {
//                        self.playbackProgress = player.playbackTime
//                        self.songDuration = nowPlayingItem.duration ?? 1
//                        self.isPlaying = state.playbackStatus == .playing
//                    }
//                } else {
//                    await MainActor.run {
//                    }
//                }
                await MainActor.run {
                    self.isPlaying = state.playbackStatus == .playing
                    self.playbackProgress = player.playbackTime
                    if let queueEntry = player.queue.currentEntry?.item,
                       case .song(let nowPlayingItem) = queueEntry {
                        self.songDuration = nowPlayingItem.duration ?? 1
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

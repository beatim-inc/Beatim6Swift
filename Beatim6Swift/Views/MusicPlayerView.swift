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
            // シーケンスバー
            Slider(value: $playbackProgress, in: 0...songDuration)
                .padding()
            
            HStack (spacing: 40){
                //頭出しボタン
                Button(action:{
                    Task{
                        stepSoundManager.playSoundPeriodically(BPM:spmManager.spm)
                        ApplicationMusicPlayer.shared.restartCurrentEntry()
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
                    Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .resizable()
                        .frame(width: 50, height: 50)
                        .foregroundColor(.blue)
                }
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

                if state.playbackStatus == .playing, let queueEntry = player.queue.currentEntry?.item,
                   case .song(let nowPlayingItem) = queueEntry {
                    await MainActor.run {
                        self.playbackProgress = player.playbackTime
                        self.songDuration = nowPlayingItem.duration ?? 1
                    }
                } else {
                    await MainActor.run {
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
            } catch {
                print(error.localizedDescription)
            }
        }
    }
}

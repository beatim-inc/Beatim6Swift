//
//  ContentView.swift
//  Beatim6Swift
//
//  Created by 野村健介 on 2025/02/17.
//

import SwiftUI
import CoreBluetooth
import MusicKit


struct ContentView: View {
    @StateObject var bleManager = BLEManager()
    @StateObject var authManager = AuthManager()
    @State private var selectedPeripheral: CBPeripheral?
    @State private var musicSubscription: MusicSubscription?
    @State private var selectedSound: String = StepSoundManager.shared.soundName
    @StateObject var stepSoundManager = StepSoundManager()
    @State private var musicDefaultBpm: Double = 120
    @StateObject var spmManager = SPMManager()
    @State private var currentSongTitle: String = "Not Playing"
    @State private var playbackTimer: Timer?

    var body: some View {
        NavigationView {
                Form {
                    // // Apple Music Authorization
                    // Section {
                    //     NavigationLink(destination: AuthView(authManager: authManager)) { // 🎯 修正
                    //         Text("Auth")
                    //     }
                    //     NavigationLink("Subscription Information") {
                    //         SubscriptionInfoView()
                    //     }
                    // }

                    // Sensor
                    Section {
                        NavigationLink(destination: SensorListView(bleManager: bleManager)) {
                            HStack {
                                Text("Connected Sensors")
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                Text("\(bleManager.connectedPeripherals.count)")
                                    .foregroundColor(.gray)
                                    .frame(alignment: .trailing)
                            }
                        }
                        HStack {
                            Text("SPM")
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Text("\(String(format: "%.2f", spmManager.spm))")
                                .foregroundColor(.gray)
                                .frame(alignment: .trailing)
                        }
                    }

                    // Music Selection
                    Section {
                        NavigationLink(destination: SearchAlbumView()) {
                            HStack {
                                Text("Album")
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                Text("ALBUM_TITLE")
                                    .foregroundColor(.gray)
                                    .frame(alignment: .trailing)
                            }
                        }
                        NavigationLink(destination: SearchSongsView()) {
                            HStack {
                                Text("Song")
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                Text(currentSongTitle)
                                    .foregroundColor(.gray)
                                    .frame(alignment: .trailing)
                            }
                        }
                        NavigationLink(destination: BpmSettingView(bpm: musicDefaultBpm, onBpmUpdate: { newBpm in
                            musicDefaultBpm = newBpm
                        })) {
                            HStack {
                                Text("Default BPM")
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                Text("\(String(format: "%.2f", musicDefaultBpm))")
                                    .foregroundColor(.gray)
                                    .frame(alignment: .trailing)
                            }
                        }
                        HStack {
                            Text("Playback Rate")
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Text("\(String(format: "%.2f", spmManager.spm / musicDefaultBpm))")
                                .foregroundColor(.gray)
                                .frame(alignment: .trailing)
                        }
                    }

                    // Step Sound Selection
                    Section {
                        NavigationLink(destination: StepSoundSelectionView(
                            selectedSound: $stepSoundManager.soundName,
                            setSoundName: stepSoundManager.setSoundName
                        )) {
                            HStack {
                                Text("Step Sound")
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                Text("\(stepSoundManager.soundName)")
                                    .foregroundColor(.gray)
                                    .frame(alignment: .trailing)
                            }
                        }
                    }
            }.navigationTitle("Beatim")
        }
        .onAppear{
            authManager.requestMusicAuthorization()
            bleManager.startScanning()
            startMusicPlaybackObserver() // 🎯 Apple Music の現在の曲情報を定期監視
            bleManager.onStepDetectionNotified = {
                print("step detection notified")
                stepSoundManager.playSound()
                spmManager.addStepData()
                spmManager.calculateSPM()
                
                if(spmManager.spm > 200 || spmManager.spm < 10) {
                    return;
                }

                // 前回更新したSPMとの差が5%以上の場合のみ更新
                let changeRate = abs(spmManager.spm - spmManager.lastUpdatedSPM) / spmManager.lastUpdatedSPM
                if changeRate < 0.10 { // 10%未満の変化なら更新しない
                    return
                }
                
                // playbackRate 更新
                ApplicationMusicPlayer.shared.state.playbackRate = 
                    Float(spmManager.spm / musicDefaultBpm)
                
                // 更新したSPMを記録
                spmManager.lastUpdatedSPM = spmManager.spm
            }
            //TODO:見つかるまでスキャンを繰り返す
            for _ in 0..<10 {
            bleManager.startScanning()
            }
        }
        .onDisappear {
            stopMusicPlaybackObserver() // 🎯 画面を離れたらタイマーを停止
        }
        .task {
            for await subscription in MusicSubscription.subscriptionUpdates {
                self.musicSubscription = subscription
            }
        }
    }

    private func startMusicPlaybackObserver() {
        print("startMusicPlaybackObserver")
        
        playbackTimer?.invalidate() // 既存のタイマーがあれば停止
        playbackTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
            Task {
                let player = ApplicationMusicPlayer.shared
                let state = player.state // 🎯 現在のプレイヤー状態を取得

                if state.playbackStatus == .playing { // 🎯 再生中の場合のみ取得
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { // 🎯 1秒遅らせて取得
                        if let queueEntry = player.queue.currentEntry?.item,
                        case .song(let nowPlayingItem) = queueEntry { // 🎯 `case .song(let nowPlayingItem)` で取り出す
                            let title = nowPlayingItem.title
                            let artist = nowPlayingItem.artistName
                            let album = nowPlayingItem.albumTitle ?? ""
                            print("🎵 再生中: \(title) - \(artist) (\(album))")

                            DispatchQueue.main.async {
                                self.currentSongTitle = "\(title) - \(artist)"
                            }
                        } else {
                            print("⚠️ queue.currentEntry が Song ではありません")
                        }
                    }
                } else {
                    DispatchQueue.main.async {
                        self.currentSongTitle = "Not Playing"
                    }
                    print("🎵 再生中ではないため、曲情報をリセット")
                }
            }
        }
    }


    // 🎯 画面を離れたときにタイマーを停止
    private func stopMusicPlaybackObserver() {
        playbackTimer?.invalidate()
        playbackTimer = nil
    }
}

#Preview {
    ContentView()
}

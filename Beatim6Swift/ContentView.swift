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
    @StateObject var authManager = AuthManager()
    @StateObject var bleManager = BLEManager()
    @StateObject var spmManager = SPMManager()
    @StateObject var stepSoundManager = StepSoundManager()

    @State private var musicSubscription: MusicSubscription?
    @State private var selectedPeripheral: CBPeripheral?
    @State private var playbackTimer: Timer?
    
    @State private var currentPlaylistTitle: String = ""
    @State private var currentAlbumTitle: String = ""
    @State private var currentSongTitle: String = "Not Playing"
    @State private var musicDefaultBpm: Double = 120
    @State private var selectedSound: String = StepSoundManager.shared.soundName
    
    // Playlist 検索用の ViewModel を保持
    @StateObject var searchPlaylistVM = SearchPlaylistViewModel()
    
    @State private var isNavigatingToSearchPlaylist = false

    var body: some View {
        NavigationStack {
                Form {
                    // // Apple Music Authorization
                    // Section {
                    //     NavigationLink(destination: AuthView(authManager: authManager)) {
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
                        NavigationLink(destination: SpmSettingView(spm: spmManager.spm, onSpmUpdate: { newSpm in
                            spmManager.spm = newSpm
                        })) {
                            HStack {
                                Text("SPM")
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                Text("\(String(format: "%.1f", spmManager.spm))")
                                    .foregroundColor(.gray)
                                    .frame(alignment: .trailing)
                            }
                        }

                        Toggle("Auto SPM Update", isOn: $spmManager.allowStepUpdate)

                        Button("add step manually"){
                            stepSoundManager.playSound()
                            if spmManager.allowStepUpdate {
                                spmManager.addStepData()
                            }
                        }

                    }

                    // Music Selection
                    Section {
                        Button {
                            isNavigatingToSearchPlaylist = true
                        } label: {
                            HStack {
                                Text("Playlist")
                                    .foregroundColor(.primary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                Spacer()
                                Text(currentPlaylistTitle)
                                    .foregroundColor(.gray)
                                    .frame(alignment: .trailing)
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14)) // やや小さめに設定
                                    .foregroundColor(.secondary) // システムのセカンダリカラーを使用
                            }
                        }
                        NavigationLink(destination: SearchAlbumView()) {
                            HStack {
                                Text("Album")
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                Text(currentAlbumTitle)
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
                            .onChange(of: currentSongTitle) { _,_ in
                                if spmManager.spm > 10 && spmManager.spm < 200 {
                                    updatePlaybackRate()
                                }
                            }
                        }
                        NavigationLink(destination: BpmSettingView(bpm: musicDefaultBpm, onBpmUpdate: { newBpm in
                            musicDefaultBpm = newBpm
                        })) {
                            HStack {
                                Text("Default BPM")
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                Text("\(String(format: "%.1f", musicDefaultBpm))")
                                    .foregroundColor(.gray)
                                    .frame(alignment: .trailing)
                            }
                        }
                        HStack {
                            Text("Playback Rate")
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Text("\(String(format: "%.2f", ApplicationMusicPlayer.shared.state.playbackRate))")
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
            }
            .navigationTitle("Beatim")
            .navigationDestination(isPresented: $isNavigatingToSearchPlaylist) {
                SearchPlaylistView(viewModel: searchPlaylistVM)
            }
        }
        .onAppear{
            authManager.requestMusicAuthorization()
            bleManager.startScanning()
            startMusicPlaybackObserver() // 🎯 Apple Music の現在の曲情報を定期監視

            bleManager.onStepDetectionNotified = {
                print("step detection notified")
                stepSoundManager.playSound()
                if spmManager.allowStepUpdate {
                    spmManager.addStepData()
                }
            }
            //TODO:見つかるまでスキャンを繰り返す
            for _ in 0..<10 {
                bleManager.startScanning()
            }
        }
        .onChange(of: spmManager.spm) { oldSPM, newSPM in
            if newSPM > 10 && newSPM < 200 {
                updatePlaybackRate()
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

    /// Apple Music の現在の曲情報を定期監視
    private func startMusicPlaybackObserver() {
        print("startMusicPlaybackObserver")
        
        playbackTimer?.invalidate() // 既存のタイマーがあれば停止
        playbackTimer = Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { _ in
            Task {
                if await isNavigatingToSearchPlaylist { return }
                
                let player = ApplicationMusicPlayer.shared
                let state = player.state // 🎯 現在のプレイヤー状態を取得
                
                if state.playbackStatus == .playing { // 🎯 再生中の場合のみ取得
                    // 0.1秒待機（Task.sleep はナノ秒単位）
                    try? await Task.sleep(nanoseconds: 100_000_000)
                    
                    if let queueEntry = player.queue.currentEntry?.item,
                        case .song(let nowPlayingItem) = queueEntry { // 🎯 `case .song(let nowPlayingItem)` で取り出す
                            let title = nowPlayingItem.title
                            let artist = nowPlayingItem.artistName
                            let album = nowPlayingItem.albumTitle ?? ""
                            print("🎵 再生中: \(title) - \(artist) (\(album))")

                            await MainActor.run {
                                self.currentSongTitle = title
                                self.currentAlbumTitle = "\(album) - \(artist)"
                            }
                        } else {
                        print("⚠️ queue.currentEntry が Song ではありません")
                        }
                    } else {
                        await MainActor.run {
                            self.currentSongTitle = "Not Playing"
                            self.currentAlbumTitle = ""
                        }
                    print("🎵 再生中ではないため、曲情報をリセット")
                }
            }
        }
    }

    /// 画面を離れたときにタイマーを停止
    private func stopMusicPlaybackObserver() {
        playbackTimer?.invalidate()
        playbackTimer = nil
    }

    /// 再生速度の更新
    private func updatePlaybackRate() {
        let player = ApplicationMusicPlayer.shared
        let state = player.state
        if state.playbackStatus == .playing {
            player.state.playbackRate = Float(spmManager.spm / musicDefaultBpm)
        }
    }
}

#Preview {
    ContentView()
}

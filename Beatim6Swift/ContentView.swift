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
    @StateObject var parameters = StepDetectionParameters()
    @StateObject var spmManager = SPMManager()
    @StateObject private var stepSoundManager = StepSoundManager()

    @State private var musicSubscription: MusicSubscription?
    @State private var selectedPeripheral: CBPeripheral?
    @State private var playbackTimer: Timer?
    
    @State private var currentPlaylistTitle: String = ""
    @State private var currentArtistName: String? = nil
    @State private var currentAlbumTitle: String = ""
    @State private var currentSongTitle: String = "Not Playing"
    @State private var trackId: String? = nil
    @State private var musicDefaultBpm: Double = 0
    @State private var isNavigatingToSearchPlaylist = false
    @State private var bpmErrorMessage: String = ""
    
    @StateObject var bleManager: BLEManager
    @State private var showSensorList = false
    @State private var showStepSettings = false
    
    init() {
        let params = StepDetectionParameters()
        _parameters = StateObject(wrappedValue: params)
        _bleManager = StateObject(wrappedValue: BLEManager(parameters: params))
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            NavigationStack {
                Form {
                    // Music Selection
                    Section {
                        NavigationLink(destination: SearchSongsView(musicDefaultBpm: musicDefaultBpm, currentArtistName: $currentArtistName).environmentObject(stepSoundManager).environmentObject(spmManager)) {
                            HStack {
                                Image(systemName: "magnifyingglass")
                                Text("Search Songs")
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .onChange(of: currentSongTitle) { _,_ in
                                if spmManager.spm > 10 && spmManager.spm < 200 {
                                    updatePlaybackRate()
                                }
                            }
                        }
                    }
                    Section {
                        NavigationLink(destination: StepSoundSelectionView(
                            selectedRightStepSound: $stepSoundManager.rightStepSoundName,
                            selectedLeftStepSound: $stepSoundManager.leftStepSoundName,
                            setSoundName: stepSoundManager.setRightStepSoundName
                            )
                            .environmentObject(stepSoundManager)) {
                            HStack {
                                Image("Drums")
                                    .resizable()
                                    .renderingMode(.template)
                                    .foregroundColor(.primary)
                                    .scaledToFit()
                                    .frame(width: 20, height: 20)
                                Text("Step Instruments")
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                Text("\(stepSoundManager.leftStepSoundName) / \(stepSoundManager.rightStepSoundName)")
                                    .foregroundColor(.gray)
                                    .frame(alignment: .trailing)
                                
                            }
                        }
                    }
                }
            }
            .onAppear{
                authManager.requestMusicAuthorization()
                bleManager.startScanning()

                bleManager.onRStepDetectionNotified = {
                    stepSoundManager.playRightStepSound()
                    if spmManager.allowStepUpdate {
                        spmManager.addStepData()
                    }
                }

                bleManager.onLStepDetectionNotified = {
                    stepSoundManager.playLeftStepSound()
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
            .onChange(of: musicDefaultBpm) { _, _ in
                if spmManager.spm > 10 && spmManager.spm < 200 {
                    updatePlaybackRate()
                }
            }
            .onChange(of: trackId) { _, _ in
                fetchBPMForCurrentSong()
            }
            .task {
                for await subscription in MusicSubscription.subscriptionUpdates {
                    self.musicSubscription = subscription
                }
            }
            
            
            VStack {
                Spacer()
                MusicPlayerView(
                    songTitle: $currentSongTitle,
                    artistName: $currentArtistName,
                    trackId: $trackId,
                    bpmErrorMessage: $bpmErrorMessage,
                    stepSoundManager: stepSoundManager,
                    spmManager: spmManager,
                    musicDefaultBpm: $musicDefaultBpm
                )
                    .frame(maxWidth: .infinity)
                    .background(.ultraThinMaterial) // iOS 標準の半透明背景
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal, 16)
                    .shadow(radius: 5)
            }
            .padding(.vertical)
        }
        .toolbar {
            ToolbarItemGroup(placement: .bottomBar) {
                HStack {
                    Button(action: { showSensorList = true }) {
                        VStack {
                            Image(systemName: "sensor.fill")
                                .foregroundColor(.primary)
                            Text("\(bleManager.connectedPeripherals.count) Sensors")
                                .font(.caption)
                                .foregroundColor(.primary)
                            
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                    }
                    .sheet(isPresented: $showSensorList) {
                        SensorListView(bleManager: bleManager)
                            .presentationDetents([.medium])
                    }
                    
                    Button(action: { showStepSettings = true }) {
                        VStack {
                            Image(systemName: "light.beacon.max.fill")
                                .foregroundColor(.primary)
                            Text("Sensitivity")
                                .font(.caption)
                                .foregroundColor(.primary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                    }
                    .sheet(isPresented: $showStepSettings) {
                        StepDetectionSettings(parameters: parameters)
                            .presentationDetents([.medium])
                    }
                }
                .padding()
            }
        }
    }
    
    struct SpacerView: View {
        var body: some View {
            Color.clear
                .frame(height: 120) // 🎯 `MusicPlayerView` の高さに合わせて余白を確保
        }
    }

    /// 再生速度の更新
    private func updatePlaybackRate() {
        let player = ApplicationMusicPlayer.shared
        let state = player.state
        if state.playbackStatus == .playing {
            player.state.playbackRate = Float(spmManager.spm / musicDefaultBpm)
        }
    }
    
    /// 現在の曲名からBPMを取得
    private func fetchBPMForCurrentSong() {
        guard currentSongTitle != "Not Playing" else {
            print("No song is currently playing.")
            return
        }

        let fetcher = BPMFetcher()
        let artist = currentArtistName ?? "Unknown Artist" // artistNameがnilの場合のデフォルト値

        print("song: \(currentSongTitle), artist: \(artist)")

        fetcher.fetchBPM(song: currentSongTitle, artist: artist) { bpmValue in
            DispatchQueue.main.async {
                if let bpmValue = bpmValue, let bpmDouble = Double(bpmValue) {
                    musicDefaultBpm = bpmDouble  // ✅ musicDefaultBpmを更新
                    updatePlaybackRate()        // ✅ BPM更新後に再生速度を変更
                    print("Updated BPM: \(bpmDouble)")
                    bpmErrorMessage = ""
                } else {
                    print("Failed to fetch BPM")
                    bpmErrorMessage = "\n⚠️ Failed to fetch BPM"
                }
            }
        }
    }

}

#Preview {
    ContentView()
}

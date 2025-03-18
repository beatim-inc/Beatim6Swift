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
    @StateObject var searchPlaylistVM = SearchPlaylistViewModel()

    @State private var musicSubscription: MusicSubscription?
    @State private var selectedPeripheral: CBPeripheral?
    @State private var playbackTimer: Timer?
    
    @State private var currentPlaylistTitle: String = ""
    @State private var currentArtistName: String? = nil
    @State private var currentAlbumTitle: String = ""
    @State private var currentSongTitle: String = "Not Playing"
    @State private var musicDefaultBpm: Double = 93.0
    @State private var isNavigatingToSearchPlaylist = false
    @State private var bpm: String = "Tap the button to fetch BPM"
    
    @StateObject var bleManager: BLEManager
    
    init() {
        let params = StepDetectionParameters()
        _parameters = StateObject(wrappedValue: params)
        _bleManager = StateObject(wrappedValue: BLEManager(parameters: params))
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            NavigationStack {
                Form {
                    // Sensor
                    Section {
                        NavigationLink(destination: SensorListView(bleManager: bleManager)) {
                            HStack {
                                Text("Step Sensors Connection")
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                Text("\(bleManager.connectedPeripherals.count)")
                                    .foregroundColor(.gray)
                                    .frame(alignment: .trailing)
                            }
                        }
                        NavigationLink(destination: StepDetectionSettings(parameters: parameters)) {
                            HStack {
                                Text("Sensitivity Settings")
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        NavigationLink(destination: SpmSettingView(spm: spmManager.spm, onSpmUpdate: { newSpm in
                            spmManager.spm = newSpm
                        })) {
                            HStack {
                                Text("Step Per Minute (SPM)")
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                Text("\(String(format: "%.1f", spmManager.spm))")
                                    .foregroundColor(.gray)
                                    .frame(alignment: .trailing)
                            }
                        }

                        Toggle("Update SPM every 10 steps", isOn: $spmManager.allowStepUpdate)

//                        Button("Add step manually"){
//                            stepSoundManager.playRightStepSound()
//                            if spmManager.allowStepUpdate {
//                                spmManager.addStepData()
//                            }
//                        }
                        
                        NavigationLink(destination: StepSoundSelectionView(
                            selectedRightStepSound: $stepSoundManager.rightStepSoundName,
                            selectedLeftStepSound: $stepSoundManager.leftStepSoundName,
                            setSoundName: stepSoundManager.setRightStepSoundName
                            )
                            .environmentObject(stepSoundManager)) {
                            HStack {
                                Text("Step Sound")
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                //NOTE:StepSound名は隠すor実験者しかわからないラベルをつける
                                
                                Text("\(stepSoundManager.leftStepSoundName) / \(stepSoundManager.rightStepSoundName)")
                                    .foregroundColor(.gray)
                                    .frame(alignment: .trailing)
                                
                            }
                        }
                    }

                    // Music Selection
                    Section {
                        NavigationLink(destination: SearchSongsView(musicDefaultBpm: musicDefaultBpm).environmentObject(stepSoundManager).environmentObject(spmManager)) {
                            HStack {
                                Text("Search Songs")
                                    .frame(maxWidth: .infinity, alignment: .leading)
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
                            .onChange(of: musicDefaultBpm) { _,_ in
                                if spmManager.spm > 10 && spmManager.spm < 200 {
                                    updatePlaybackRate()
                                }
                            }
                        }
                        HStack {
                            Text("Playback Rate")
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Text("\(String(format: "%.2f", spmManager.spm / musicDefaultBpm))")
                                .foregroundColor(.gray)
                                .frame(alignment: .trailing)
                        }
//
//                        Button(action: {
//                            
//                        }) {
//                            Text(musicDefaultBpm == 0 ? "Fetch BPM" : "Update BPM")
//                                .padding()
//                                .frame(maxWidth: .infinity)
//                                .cornerRadius(10)
//                        }
                    }

                    Section(footer: SpacerView()) {}
                }
                .navigationTitle("Step Drummer")
                .navigationDestination(isPresented: $isNavigatingToSearchPlaylist) {
                    SearchPlaylistView(viewModel: searchPlaylistVM)
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
            .onChange(of: currentSongTitle) { _, _ in
                guard !currentSongTitle.isEmpty else {
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
                            bpm = "BPM: \(bpmValue)"
                        } else {
                            bpm = "Failed to fetch BPM"
                        }
                        print(bpm)
                    }
                }
            }
            .task {
                for await subscription in MusicSubscription.subscriptionUpdates {
                    self.musicSubscription = subscription
                }
            }

            VStack {
                Spacer()
                MusicPlayerView(songTitle: $currentSongTitle, artistName: $currentArtistName, stepSoundManager: stepSoundManager, spmManager: spmManager, musicDefaultBpm: musicDefaultBpm)
                    .frame(maxWidth: .infinity)
                    .background(.ultraThinMaterial) // iOS 標準の半透明背景
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal, 16)
                    .shadow(radius: 5)
            }
            .padding(.vertical)
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
}

#Preview {
    ContentView()
}

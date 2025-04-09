//
//  ContentView.swift
//  Beatim6Swift
//
//  Created by 野村健介 on 2025/02/17.
//

import SwiftUI
import CoreBluetooth
import MusicKit
import AVFoundation
import RealityKit
import ARKit

struct ContentView: View {
    @StateObject var authManager = AuthManager()
    @StateObject var parameters = StepDetectionParameters()
    @StateObject var spmManager = SPMManager()
    @StateObject private var stepSoundManager = StepSoundManager()
    @StateObject private var tabManager = TabManager()
    @StateObject private var songHistoryManager = SongHistoryManager()
    @StateObject private var spreadSheetManager = SpreadSheetManager()
    @StateObject private var distanceTracker = DistanceTracker()

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
    @State private var tempoRatioEvaluationEnabled: Bool = true
    @State private var autoPause: Bool = true
    @State private var userID: String = "test"
    
    @StateObject var bleManager: BLEManager
    @State var showSettings: Bool = false
    @State var showUserSettings: Bool = false
    
    init() {
        let params = StepDetectionParameters()
        _parameters = StateObject(wrappedValue: params)
        _bleManager = StateObject(wrappedValue: BLEManager(parameters: params))
    }

    var body: some View {
        
            ZStack(alignment: .bottom) {
                TabView (selection: $tabManager.selectedTab) {
                    
                    NavigationStack {
                        SearchSongsView(
                            musicDefaultBpm: $musicDefaultBpm,
                            currentArtistName: $currentArtistName,
                            bpmErrorMessage: $bpmErrorMessage,
                            tempoRatioEvaluationEnabled: $tempoRatioEvaluationEnabled,
                            autoPause: $autoPause
                        )
                        .environmentObject(stepSoundManager)
                        .environmentObject(spmManager)
                        .environmentObject(authManager)
                        .toolbar {
                            ToolbarItem(placement: .navigation) {
                                Text(tabTitle())
                                    .font(.largeTitle)
                                    .bold()
                            }
                            ToolbarItem(placement: .navigationBarTrailing) {
                                HStack (spacing: 8) {
                                    HStack {
                                        Image(systemName: "person.crop.circle")
                                        Text("\(userID)")
                                    }
                                    .onTapGesture {
                                        showUserSettings = true
                                    }
                                    Image(systemName: "gear")
                                    .contentShape(Rectangle()) // ✅ タップ可能にする
                                    .onTapGesture {
                                        showSettings = true // ✅ タップ時にシートを開く
                                    }
                                }
                            }
                        }
                    }
                    .tabItem {
                        Image(systemName: "magnifyingglass")
                        Text("Search")
                    }
                    .tag("Search")
                    
                    NavigationStack {
                        StepSoundSelectionView(
                            selectedRightStepSound: $stepSoundManager.rightStepSoundName,
                            selectedLeftStepSound: $stepSoundManager.leftStepSoundName,
                            setSoundName: stepSoundManager.setRightStepSoundName
                        )
                        .environmentObject(stepSoundManager)
                        .toolbar {
                            ToolbarItem(placement: .navigation) {
                                Text(tabTitle())
                                    .font(.largeTitle)
                                    .bold()
                            }
                            ToolbarItem(placement: .navigationBarTrailing) {
                                HStack (spacing: 8) {
                                    HStack {
                                        Image(systemName: "person.crop.circle")
                                        Text("\(userID)")
                                    }
                                    .onTapGesture {
                                        showUserSettings = true
                                    }
                                    Image(systemName: "gear")
                                    .contentShape(Rectangle()) // ✅ タップ可能にする
                                    .onTapGesture {
                                        showSettings = true // ✅ タップ時にシートを開く
                                    }
                                }
                            }
                        }
                    }
                    .tabItem {
                        Image("Drums")
                            .renderingMode(.template)
                            .foregroundColor(.primary)
                        Text("Instruments")
                    }
                    .tag("Instruments")
                    
                }
                .sheet(isPresented: $showSettings) { // ✅ `sheet` を使ってモーダル遷移
                    SettingView(
                        bleManager: bleManager,
                        parameters: parameters,
                        spreadSheetManager: spreadSheetManager,
                        spmManager: spmManager,
                        stepSoundManager: stepSoundManager,
                        songTitle: currentSongTitle,
                        artistName: currentArtistName,
                        bpm:musicDefaultBpm,
                        tempoRatioEvaluationEnabled: $tempoRatioEvaluationEnabled,
                        userID: $userID,
                        autoPause: $autoPause
                    )
                    .presentationDetents([.large])
                    .environmentObject(distanceTracker)
                }
                .sheet(isPresented: $showUserSettings) {
                    UserSettingView(
                        userID: userID,
                        onUserIdUpdate: { newUserID in userID = newUserID }
                    )
                }
                .tint(.primary)
                .onAppear{
                    authManager.requestMusicAuthorization()
                    bleManager.startScanning()
                    
                    bleManager.onRStepDetectionNotified = {
                        stepSoundManager.playRightStepSound()
                        if !spmManager.spmLocked {
                            spmManager.addStepData()
                        }
                    }
                    
                    bleManager.onLStepDetectionNotified = {
                        stepSoundManager.playLeftStepSound()
                        if !spmManager.spmLocked {
                            spmManager.addStepData()
                        }
                    }
                    
                    do {
                        try AVAudioSession.sharedInstance().setCategory(
                            .playback,
                            mode: .default,
                            options: [.mixWithOthers]
                        )
                        try AVAudioSession.sharedInstance().setActive(true)
                    } catch {
                        print("⚠️ Audio session setup failed: \(error)")
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
                    fetchBPMForCurrentSong()
                    updatePlaybackRate()
                }
                .task {
                    for await subscription in MusicSubscription.subscriptionUpdates {
                        self.musicSubscription = subscription
                    }
                }
                .environmentObject(tabManager)
                .environmentObject(songHistoryManager)
                
                VStack {
                    Spacer()
                    MusicPlayerView(
                        songTitle: $currentSongTitle,
                        artistName: $currentArtistName,
                        trackId: $trackId,
                        bpmErrorMessage: $bpmErrorMessage,
                        stepSoundManager: stepSoundManager,
                        spmManager: spmManager,
                        musicDefaultBpm: $musicDefaultBpm,
                        autoPause: $autoPause,
                        userID: $userID
                    )
                    .frame(maxWidth: .infinity)
                    .background(.ultraThinMaterial) // iOS 標準の半透明背景
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal, 16)
                    .shadow(radius: 5)
                    .environmentObject(songHistoryManager)
                    .environmentObject(spreadSheetManager)
                    .environmentObject(distanceTracker)
                }
                .padding(.top, 20)
                .padding(.bottom, 64)
            }
            .ignoresSafeArea(.keyboard)
        }
    
    
    /// 再生速度の更新
    private func updatePlaybackRate() {
        let player = ApplicationMusicPlayer.shared
        player.state.playbackRate = Float(spmManager.spm / musicDefaultBpm)
        print("Update playbackRate: \(player.state.playbackRate)")
    }
    
    /// 現在の曲名からBPMを取得
    private func fetchBPMForCurrentSong() {
        guard currentSongTitle != "Not Playing" else {
            print("No song is currently playing.")
            return
        }

        let fetcher = BPMFetcher(historyManager: songHistoryManager)
        let artist = currentArtistName ?? "Unknown Artist" // artistNameがnilの場合のデフォルト値
        guard let trackId = trackId else {
            print("Failed to fetch track ID.")
            return
        }

        print("song: \(currentSongTitle), artist: \(artist)")

        fetcher.fetchBPM(song: currentSongTitle, artist: artist, id: trackId) { bpmValue in
            DispatchQueue.main.async {
                if let bpmDouble = bpmValue {
                    musicDefaultBpm = bpmDouble  // ✅ musicDefaultBpmを更新
                    updatePlaybackRate()        // ✅ BPM更新後に再生速度を変更
                    print("Updated BPM: \(bpmDouble)")
                    bpmErrorMessage = ""
                } else {
                    print("Failed to fetch BPM")
                    bpmErrorMessage = "⚠️"
                    ApplicationMusicPlayer.shared.pause() // BPMを取得できなかったときは再生をとめる
                }
            }
        }
    }
    
    /// タブのタイトルを管理
    private func tabTitle() -> String {
        switch tabManager.selectedTab {
            case "Instruments": return "Instruments"
            case "Search": return "Search"
            default: return ""
        }
    }
}

#Preview {
    ContentView()
}

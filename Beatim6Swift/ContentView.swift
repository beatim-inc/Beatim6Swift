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
    @State private var selectedPeripheral: CBPeripheral?
    @State private var musicSubscription: MusicSubscription?
    @State private var selectedSound: String = StepSoundManager.shared.soundName
    @StateObject var stepSoundManager = StepSoundManager()
    @State private var musicDefaultBpm: Double = 120
    @StateObject var spmManager = SPMManager()
    var body: some View {
        NavigationView {
                VStack {
                    VStack{
                        List{
                            NavigationLink(destination: SensorListView(bleManager: bleManager)) {
                                    Text("Connected Sensors: \(bleManager.peripherals.count)")
                                }
                            Text("SPM: \(spmManager.spm)")
                        }
                        .frame(height: 120).background(Color(.systemGray6))
                    }
                    //Music
                    VStack{
                        List{
                            NavigationLink("BPM: \(musicDefaultBpm)"){
                                BpmSettingView(bpm:musicDefaultBpm,
                                onBpmUpdate: { newBpm in
                                musicDefaultBpm = newBpm
                                }
                                )
                            }
                            Text("Playback Rate:\(spmManager.spm/musicDefaultBpm)")
                            Text("Music Title: MUSIC_TITLE")
                            NavigationLink("Search for music") {
                                SearchSongsView()
                            }
                        }
                        .frame(height:200)}
                    //StepSound
                    VStack{
                        List{
                            NavigationLink(
                                destination: StepSoundSelectionView(
                                    selectedSound: $stepSoundManager.soundName,
                                    setSoundName: stepSoundManager.setSoundName
                                )
                            )
                            {
                                Text("Step Sound: \(stepSoundManager.soundName)")
                            }
                        }.frame(height:120)}
                    List {
                        NavigationLink("Auth") {
                            AuthView()
                        }
                        NavigationLink("Subscription Information") {
                            SubscriptionInfoView()
                        }
                        NavigationLink("Search for album") {
                            SearchAlbumView()
                        }
                    }
                }.navigationTitle("Beatim")
        }
        .onAppear{
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
        .task {
            for await subscription in MusicSubscription.subscriptionUpdates {
                self.musicSubscription = subscription
            }
        }
    }
}

#Preview {
    ContentView()
}

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
                                Text("Connected Sensors: \(bleManager.peripherals.count)")
                            }
                        Text("SPM: \(spmManager.spm)")
                    }

                    // Music Selection
                    Section{
                        NavigationLink("Album: ALBUM_TITLE") {
                            SearchAlbumView()
                        }
                        NavigationLink("Music: MUSIC_TITLE") {
                            SearchSongsView()
                        }
                        NavigationLink("Defoult BPM: \(musicDefaultBpm)"){
                            BpmSettingView(bpm:musicDefaultBpm,
                            onBpmUpdate: { newBpm in
                            musicDefaultBpm = newBpm
                            }
                            )
                        }
                        Text("Playback Rate: \(spmManager.spm/musicDefaultBpm)")
                    }

                    // Step Sound Selection
                    Section{
                        NavigationLink(
                            destination: StepSoundSelectionView(
                                selectedSound: $stepSoundManager.soundName,
                                setSoundName: stepSoundManager.setSoundName
                            )
                        )
                        {
                            Text("Step Sound: \(stepSoundManager.soundName)")
                        }
                    }

                    
            }.navigationTitle("Beatim")
        }
        .onAppear{
            authManager.requestMusicAuthorization()
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

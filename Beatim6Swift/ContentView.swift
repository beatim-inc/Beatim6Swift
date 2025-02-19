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
    @State private var musicDefaultBpm: Double = 120
    let spmManager = SPMManager()
    let stepSoundManager = StepSoundManager()
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
                            //TODO:入力
                            Text("BPM: \(musicDefaultBpm)")
                            Text("Music Title: MUSIC_TITLE")
                            NavigationLink("Search for music") {
                                SearchSongsView()
                            }
                        }
                        .frame(height:180)}
                    //StepSound
                    VStack{
                        List{
                            Text("step sound:\(stepSoundManager.soundName)")
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
        }.onAppear{
            bleManager.onStepDetectionNotified = {
                print("step detection notified")
                stepSoundManager.playSound()
                spmManager.addStepData()
                spmManager.calculateSPM()
                if(spmManager.spm > 200 || spmManager.spm < 10) {
                    return;
                }
                ApplicationMusicPlayer.shared.state.playbackRate =
                //TODO曲に合わせる
                Float(spmManager.spm/musicDefaultBpm)
            }
            //TODO:見つかるまでスキャンを繰り返す
            for _ in 0..<10 {
            bleManager.startScanning()
            }
        }.task {
            for await subscription in MusicSubscription.subscriptionUpdates {
                self.musicSubscription = subscription
            }
        }
    }
}

#Preview {
    ContentView()
}

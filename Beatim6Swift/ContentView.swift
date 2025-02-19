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
    let stepSoundManager = StepSoundManager()
    var body: some View {
        NavigationView {
                  VStack {
                      List(bleManager.peripherals, id: \..identifier) { peripheral in
                          Button(action: {
                              selectedPeripheral = peripheral
                              bleManager.connectPeripheral(peripheral: peripheral)
                          }) {
                              Text(peripheral.name ?? "Unknown")
                          }
                      }
                      .navigationTitle("BLE Devices")
                      Button("Connect All") {
                          for peripheral in bleManager.peripherals {
                                 bleManager.connectPeripheral(peripheral: peripheral)
                             }
                      }
                      Button("Scan Again") {
                          bleManager.startScanning()
                      }
                      List {
                          NavigationLink("Auth") {
                              AuthView()
                          }
                          NavigationLink("Subscription Information") {
                              SubscriptionInfoView()
                          }
                          NavigationLink("Search for music") {
                              SearchSongsView()
                          }
                          NavigationLink("Search for album") {
                              SearchAlbumView()
                          }
                      }
                      .navigationTitle("Auth and set Music")
                  }
        }.onAppear{
            bleManager.onStepDetectionNotified = {
                print("step detection notified")
                stepSoundManager.playSound()
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

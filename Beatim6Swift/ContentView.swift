//
//  ContentView.swift
//  Beatim6Swift
//
//  Created by 野村健介 on 2025/02/17.
//

import SwiftUI
import CoreBluetooth


struct ContentView: View {
    @StateObject var bleManager = BLEManager()
    @State private var selectedPeripheral: CBPeripheral?
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
                      .padding()
                  }
        }.onAppear{
            bleManager.onStepDetectionNotified = {
                print("step detection notified")
                stepSoundManager.playSound()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                bleManager.startScanning()
            }
        }
    }
}

#Preview {
    ContentView()
}

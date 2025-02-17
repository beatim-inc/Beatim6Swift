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

                      Button("Scan for Devices") {
                          print(bleManager.isSwitchedOn)
                          bleManager.startScanning()
                      }
                      Button("Play Sound") {
                          print("Play Sound")
                         // SoundManager.playSound()
                      }
                      .padding()
                  }
              }
    }
}

#Preview {
    ContentView()
}

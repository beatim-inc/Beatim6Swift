//
//  SensorListView.swift
//  Beatim6Swift
//
//  Created by 野村健介 on 2025/02/19.
//

import Foundation
import SwiftUI

struct SensorListView: View {
    @ObservedObject var bleManager: BLEManager

    var body: some View {
        VStack {
            List(bleManager.peripherals, id: \..identifier) { peripheral in
                                      Button(action: {
                                          bleManager.connectPeripheral(peripheral: peripheral)
                                      }) {
                                          Text(peripheral.name ?? "Unknown")
                                      }
                                  }
            
            
            Button("Connect All") {
                for peripheral in bleManager.peripherals {
                    bleManager.connectPeripheral(peripheral: peripheral)
                }
            }
            .padding()

            Button("Scan Again") {
                bleManager.startScanning()
            }
            .padding()
        }
        .navigationTitle("Sensor List")
    }
}

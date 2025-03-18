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
        Form {
            Section {
                List(bleManager.peripherals, id: \..identifier) { peripheral in
                    Button(action: {
                        bleManager.connectPeripheral(peripheral: peripheral)
                    }) {
                        Text(peripheral.name ?? "Unknown")
                    }
                }
            }

            Section {
                Button("Scan Sensors") {
                bleManager.startScanning()
            }
            Button("Connect All") {
                bleManager.autoConnectAllPeripherals()
            }
            }
        }
        .navigationTitle("Sensors Connection")
    }
}

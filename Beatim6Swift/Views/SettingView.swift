//
//  SettingView.swift
//  Beatim6Swift
//
//  Created by heilab on 2025-03-21.
//

import Foundation
import SwiftUI

struct SettingView: View {
    @ObservedObject var bleManager: BLEManager
    @ObservedObject var parameters: StepDetectionParameters
    @Binding var skipEvaluation: Bool

    init(
        bleManager: BLEManager,
        parameters: StepDetectionParameters,
        skipEvaluation: Binding<Bool>
    ) {
        self.bleManager = bleManager
        self.parameters = parameters
        self._skipEvaluation = skipEvaluation
    }

    var body: some View {
        NavigationView {
            Form {
                
                Section (header: Text("Sensors")) {
                    Toggle("Enable Scanning", isOn: $bleManager.scanEnabled)
                    List(bleManager.peripherals, id: \..identifier) { peripheral in
                        Button(action: {
                            bleManager.connectPeripheral(peripheral: peripheral)
                        }) {
                            Text(peripheral.name ?? "Unknown")
                        }
                    }
                    Button("Scan Sensors") {
                        bleManager.startScanning()
                    }
                    Button("Connect All") {
                        bleManager.autoConnectAllPeripherals()
                    }
                }
                
                
                Section (header: Text("Sensitivity")) {
                    VStack(alignment: .leading) {
                        
                        Text("Step Acceleration Threshold (G)")
                        Slider(value: Binding(
                            get: { -parameters.azThreshould },  // スライダー表示値 (0 から 3)
                            set: { parameters.azThreshould = -$0 } // 内部値を 0 から -3 に変換
                        ), in: 0...3, step: 0.1)
                        .accentColor(.primary)
                        HStack {
                            Text("Sensitive") // 敏感
                                .font(.caption)
                                .foregroundColor(.gray)
                            Spacer()
                            Text("Current: \(-parameters.azThreshould, specifier: "%.1f") G")
                                .font(.caption)
                            Spacer()
                            Text("Dull") // 鈍い
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                        
                        Text("Debounce Time (ms)")
                        Slider(value: $parameters.debounceTime, in: 100...1000, step: 50).accentColor(.primary)
                        HStack {
                            Text("Short")
                                .font(.caption)
                                .foregroundColor(.gray)
                            Spacer()
                            Text("Current: \(parameters.debounceTime, specifier: "%.0f") ms")
                                .font(.caption)
                            Spacer()
                            Text("Long")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    .padding()
                }
                
                Section (header: Text("Skip Evaluation")) {
                    Toggle("SPM評価をスキップ", isOn: $skipEvaluation)
                }
            }
        }
    }
}

class StepDetectionParameters: ObservableObject {
    @Published var azThreshould: Float = -0.2 // 接地時Z軸加速度の閾値
    @Published var debounceTime: TimeInterval = 300 // ミリ秒
}

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
    
    /// BPM関係
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var songHistoryManager: SongHistoryManager
    @State private var bpmValue: String
    @State private var originalBpmValue: String
    var onBpmUpdate: (Double) -> Void
    @Binding var bpmErrorMessage: String
    @Binding var musicDefaultBpm: Double 
    @Binding var trackId: String?
    @State private var showBpmSetting = false

    init(
        bleManager: BLEManager,
        parameters: StepDetectionParameters,
        bpm: Double,
        trackId: Binding<String?>,
        bpmErrorMessage: Binding<String>,
        onBpmUpdate: @escaping (Double) -> Void,
        musicDefaultBpm: Binding<Double>
    ) {
        self.bleManager = bleManager
        self.parameters = parameters
        self._bpmValue = State(initialValue: String(format: "%.1f", bpm))
        self._originalBpmValue = State(initialValue: String(format: "%.1f", bpm))
        self._bpmErrorMessage = bpmErrorMessage
        self.onBpmUpdate = onBpmUpdate
        self._trackId = trackId
        self._musicDefaultBpm = musicDefaultBpm
    }

    var body: some View {
        NavigationView {
            Form {
                Section (header: Text("Connected Peripherals")) {
                    List(bleManager.peripherals, id: \..identifier) { peripheral in
                        Button(action: {
                            bleManager.connectPeripheral(peripheral: peripheral)
                        }) {
                            Text(peripheral.name ?? "Unknown")
                        }
                    }
                }
                
                Section (header: Text("Sensor Actions")) {
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
                
                Section (header: Text("BPM")) {
                    
                    HStack (spacing: 8) {
                        Image("Bpm")
                            .resizable()
                            .renderingMode(.template)
                            .foregroundColor(.primary)
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                        if bpmErrorMessage == "" {
                            Text("\(String(format: "%.1f", musicDefaultBpm))")
                                .foregroundColor(.primary)
                        } else {
                            Text(bpmErrorMessage)
                                .foregroundColor(.primary)
                        }
                    }
                    .contentShape(Rectangle()) // ✅ タップ可能にする
                    .onTapGesture {
                        showBpmSetting = true // ✅ タップ時にシートを開く
                    }
                    .sheet(isPresented: $showBpmSetting) { // ✅ `sheet` を使ってモーダル遷移
                        BpmSettingView(
                            bpm: musicDefaultBpm,
                            trackId: trackId ?? "Unknown",
                            bpmErrorMessage: $bpmErrorMessage,
                            onBpmUpdate: { newBpm in musicDefaultBpm = newBpm }
                        )
                        .presentationDetents([.height(80)])
                        .environmentObject(songHistoryManager)
                    }
                    .padding(6) // ✅ 内側の余白
                }
            }
        }
    }
}

class StepDetectionParameters: ObservableObject {
    @Published var azThreshould: Float = -0.2 // 接地時Z軸加速度の閾値
    @Published var debounceTime: TimeInterval = 300 // ミリ秒
}

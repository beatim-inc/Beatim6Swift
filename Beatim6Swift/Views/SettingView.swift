//
//  SettingView.swift
//  Beatim6Swift
//
//  Created by heilab on 2025-03-21.
//

import Foundation
import SwiftUI
import MusicKit

class StepDetectionParameters: ObservableObject {
    @Published var azThreshould: Float = -0.2 // 接地時Z軸加速度の閾値
    @Published var debounceTime: TimeInterval = 800 // ミリ秒
}

struct SettingView: View {
    @ObservedObject var bleManager: BLEManager
    @ObservedObject var parameters: StepDetectionParameters
    @ObservedObject var spreadSheetManager: SpreadSheetManager
    @ObservedObject var spmManager: SPMManager
    @ObservedObject var stepSoundManager: StepSoundManager
    @EnvironmentObject var distanceTracker: DistanceTracker
    @Binding var tempoRatioEvaluationEnabled: Bool
    @Binding var userID: String
    @State private var songTitle: String
    @State private var artistName: String?
    @State private var bpm: Double
    @Binding var autoPause: Bool


    init(
        bleManager: BLEManager,
        parameters: StepDetectionParameters,
        spreadSheetManager: SpreadSheetManager,
        spmManager: SPMManager,
        stepSoundManager: StepSoundManager,
        songTitle: String,
        artistName: String?,
        bpm:Double,
        tempoRatioEvaluationEnabled: Binding<Bool>,
        userID: Binding<String>,
        autoPause: Binding<Bool>
    ) {
        self.bleManager = bleManager
        self.parameters = parameters
        self.spreadSheetManager = spreadSheetManager
        self.spmManager = spmManager
        self.stepSoundManager = stepSoundManager
        self.songTitle = songTitle
        self.artistName = artistName
        self.bpm = bpm
        self._tempoRatioEvaluationEnabled = tempoRatioEvaluationEnabled
        self._userID = userID
        self._autoPause = autoPause
    }

    var body: some View {
        NavigationView {
            Form {
                
                Section (header: Text("Sensors")) {
                    Toggle("Enable Scanning", isOn: $bleManager.scanEnabled).tint(nil)
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
                
                Section (header: Text("Experimental Settings")) {
                    Toggle("Enable Tempo Ratio Evaluation", isOn: $tempoRatioEvaluationEnabled)
                    Toggle("Auto Pause", isOn: $autoPause)
                }
                .tint(nil)
                //ID入力
                Section (header: Text("Log")){
                    //Input Id
                    TextField("Enter ID", text: $userID)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    Button("sync"){
                        spreadSheetManager.post(
                            id:userID,
                            music:songTitle,
                            artist:artistName ?? "no artist data",
                            bpm:bpm,
                            spm:spmManager.spm,
                            rightStepSound: stepSoundManager.rightStepSoundName,
                            leftStepSound: stepSoundManager.leftStepSoundName,
                            distance: distanceTracker.distance
                        )
                    }
                }
            }
        }
    }
}

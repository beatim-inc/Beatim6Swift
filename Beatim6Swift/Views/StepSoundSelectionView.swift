//
//  StepSoundSelectionView.swift
//  Beatim6Swift
//
//  Created by Ryota-Nitto on 2025-02-19.
//

import SwiftUI

struct StepSoundSelectionView: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var selectedRightStepSound: String
    @Binding var selectedLeftStepSound: String
    @State private var isLeftPickerExpanded = false
    @State private var isRightPickerExpanded = false
    var setSoundName: (String) -> Void
    @EnvironmentObject var stepSoundManager: StepSoundManager
    let availableSounds = ["None","BaseDrum", "Clap", "ElectricalBaseDrum", "SnareDrum", "WalkOnSoil1", "WalkOnSoil2", "Claverotor1", "Claverotor2"]
    
    var body: some View {
        Form{
            Section(header: Text("Left Step Sound")) {
                
                DisclosureGroup(
                    isExpanded: $isLeftPickerExpanded,
                    content: {
                        Picker("Select Left Sound", selection: $stepSoundManager.leftStepSoundName) {
                            ForEach(availableSounds, id: \.self) { sound in
                                Text(sound).tag(sound)
                            }
                        }
                        .pickerStyle(WheelPickerStyle())
                    },
                    label: {
                        HStack {
                            Text("\(stepSoundManager.leftStepSoundName)")
                            Spacer()
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            isLeftPickerExpanded.toggle()
                        }
                    }
                )
                
                VStack {
                    Slider(value: $stepSoundManager.leftStepVolume, in: 0...2, step: 0.1)
                    HStack {
                        Text("Low")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Spacer()
                        Text("Volume: \(stepSoundManager.leftStepVolume, specifier: "%.1f")")
                            .font(.caption)
                        Spacer()
                        Text("High")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                .padding(.vertical, 8)
            }
            
            Section(header: Text("Right Step Sound")) {
                
                DisclosureGroup(
                    isExpanded: $isRightPickerExpanded,
                    content: {
                        Picker("Select Right Sound", selection: $stepSoundManager.rightStepSoundName) {
                            ForEach(availableSounds, id: \.self) { sound in
                                Text(sound).tag(sound)
                            }
                        }
                        .pickerStyle(WheelPickerStyle())
                    },
                    label: {
                        HStack {
                            Text("\(stepSoundManager.rightStepSoundName)")
                            Spacer()
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            isRightPickerExpanded.toggle()
                        }
                    }
                )
                
                VStack {
                    Slider(value: $stepSoundManager.rightStepVolume, in: 0...2, step: 0.1)
                    HStack {
                        Text("Low")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Spacer()
                        Text("Volume: \(stepSoundManager.rightStepVolume, specifier: "%.1f")")
                            .font(.caption)
                        Spacer()
                        Text("High")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                .padding(.vertical, 8)
            }
            
            Section(footer: SpacerView()) {}
        }
        .navigationTitle("Step Sound")
    }
    
    // カスタムタイトルビュー
    @ViewBuilder
    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .frame(maxWidth: .infinity, alignment: .leading) // 左揃え
            .font(.headline)
            .padding()
    }
    
    struct SpacerView: View {
        var body: some View {
            Color.clear
                .frame(height: 120) // 🎯 `MusicPlayerView` の高さに合わせて余白を確保
        }
    }
}

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
    var setSoundName: (String) -> Void
    @EnvironmentObject var stepSoundManager: StepSoundManager
    let availableSounds = ["None","BaseDrum", "Clap", "ElectricalBaseDrum", "SnareDrum", "WalkOnSoil1", "WalkOnSoil2", "Claverotor1", "Claverotor2"]
    
    var body: some View {
        Form{
            Section(header: Text("Left Step Sound")) {
                List(availableSounds, id: \..self) { sound in
                    HStack {
                        Text(sound)
                        Spacer()
                        if sound == selectedLeftStepSound {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedLeftStepSound = sound
                        StepSoundManager.shared.setLeftStepSoundName(to: sound)
                    }
                }
                VStack {
                    Slider(value: $stepSoundManager.leftStepVolume, in: 0...1, step: 0.1)
                    HStack {
                        Text("Low")
                        Spacer()
                        Text("High")
                    }
                }
                .padding(.vertical, 8)
            }
            
            Section(header: Text("Right Step Sound")) {
                List(availableSounds, id: \..self) { sound in
                    HStack {
                        Text(sound)
                        Spacer()
                        if sound == selectedRightStepSound {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedRightStepSound = sound
                        StepSoundManager.shared.setRightStepSoundName(to: sound)
                    }
                }
                VStack {
                    Slider(value: $stepSoundManager.rightStepVolume, in: 0...1, step: 0.1)
                    HStack {
                        Text("Low")
                        Spacer()
                        Text("High")
                    }
                }
                .padding(.vertical, 8)
            }
        }
        .navigationTitle("Select Step Sound")
    }
    
    // カスタムタイトルビュー
    @ViewBuilder
    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .frame(maxWidth: .infinity, alignment: .leading) // 左揃え
            .font(.headline)
            .padding()
    }
}

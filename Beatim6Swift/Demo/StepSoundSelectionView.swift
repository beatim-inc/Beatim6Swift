//
//  StepSoundSelectionView.swift
//  Beatim6Swift
//
//  Created by Ryota-Nitto on 2025-02-19.
//

import SwiftUI

struct StepSoundSelectionView: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var selectedSound: String
    var setSoundName: (String) -> Void
    let availableSounds = ["BaseDrum", "Crap", "ElectricalBaseDrum", "SnareDrum", "WalkOnSoil"]
    
    var body: some View {
            List(availableSounds, id: \..self) { sound in
                HStack {
                    Text(sound)
                    Spacer()
                    if sound == selectedSound {
                        Image(systemName: "checkmark")
                            .foregroundColor(.blue)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    selectedSound = sound
                    StepSoundManager.shared.setSoundName(to: sound)
                }
            }
            .navigationTitle("Select Step Sound")
            .toolbar {
                Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
}

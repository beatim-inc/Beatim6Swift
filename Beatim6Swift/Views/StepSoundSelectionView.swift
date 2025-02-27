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
    let availableSounds = ["None","BaseDrum", "Crap", "ElectricalBaseDrum", "SnareDrum", "WalkOnSoil1", "WalkOnSoil2"]
    
    var body: some View {
        VStack{
            Text("Right Step Sound")
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
            Text( "Left Step Sound")
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
        }
            .navigationTitle("Select Step Sound")
        }
}

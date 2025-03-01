//
//  PeriodicStepSoundSettingView.swift
//  Beatim6Swift
//
//  Created by 野村健介 on 2025/03/01.
//

import Foundation
import SwiftUI

struct PeriodicStepSoundSettingView: View {
    @ObservedObject var stepSoundManager: StepSoundManager

    var body: some View {
        Form {
            Section {
                Toggle("Periodic StepSound", isOn: $stepSoundManager.isPeriodicStepSoundActive)
            }
        }
        .navigationTitle("Periodic StepSound Setting")
    }
}

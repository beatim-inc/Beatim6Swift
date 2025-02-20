//
//  BpmSettingView.swift
//  Beatim6Swift
//
//  Created by 野村健介 on 2025/02/19.
//

import Foundation
import SwiftUI

struct BpmSettingView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var bpmValue: String
    var onBpmUpdate: (Double) -> Void

    init(bpm: Double, onBpmUpdate: @escaping (Double) -> Void) {
          _bpmValue = State(initialValue: String(format: "%.0f", bpm))
          self.onBpmUpdate = onBpmUpdate
      }

    var body: some View {
        Form {
            Section {
                TextField("Enter BPM", text: $bpmValue)
                    .keyboardType(.numberPad)
            }
        }
        .navigationTitle("BPM Setting")
        .toolbar {
            Button("Save") {
                if let newBpm = Double(bpmValue) {
                    onBpmUpdate(newBpm)
                } else {
                    print("無効な BPM 値")
                }
                presentationMode.wrappedValue.dismiss()
            }
        }
    }
}

//
//  BpmSettingView.swift
//  Beatim6Swift
//
//  Created by 野村健介 on 2025/02/19.
//

import Foundation
import SwiftUI

struct BpmSettingView: View {
    @State private var bpmValue: String
    var onBpmUpdate: (Double) -> Void

    init(bpm: Double, onBpmUpdate: @escaping (Double) -> Void) {
          _bpmValue = State(initialValue: String(format: "%.0f", bpm))
          self.onBpmUpdate = onBpmUpdate
      }

    var body: some View {
        Form {
            Section(header: Text("BPM 設定")) {
                TextField("BPM を入力", text: $bpmValue)
                    .keyboardType(.numberPad)
            }

            Section {
                Button("保存") {
                    if let newBpm = Double(bpmValue) {
                        onBpmUpdate(newBpm)
                    } else {
                        print("無効な BPM 値")
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .navigationTitle("BPM Setting")
    }
}

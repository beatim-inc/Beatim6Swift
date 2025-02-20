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
        _bpmValue = State(initialValue: String(format: "%.2f", bpm))
        self.onBpmUpdate = onBpmUpdate
    }

    var body: some View {
        Form {
            Section {
                TextField("Enter BPM", text: $bpmValue)
                    .keyboardType(.decimalPad)
                    .onChange(of: bpmValue) { oldValue, newValue in
                        bpmValue = filterNumericInput(newValue) // 🎯 入力バリデーション
                    }
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

    // 🎯 数値と1つの小数点のみ許可するバリデーション関数
    private func filterNumericInput(_ input: String) -> String {
        let allowedCharacters = "0123456789."
        let filtered = input.filter { allowedCharacters.contains($0) }
        
        // 小数点が2つ以上入力されないように制限
        let decimalCount = filtered.filter { $0 == "." }.count
        if decimalCount > 1 {
            return String(filtered.dropLast()) // 余分な小数点を削除
        }

        return filtered
    }
}

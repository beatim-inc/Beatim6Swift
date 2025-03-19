import Foundation
import SwiftUI
import UIKit

struct SpmSettingView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var spmValue: String
    var onSpmUpdate: (Double) -> Void

    init(spm: Double, onSpmUpdate: @escaping (Double) -> Void) {
        _spmValue = State(initialValue: String(format: "%.1f", spm))
        self.onSpmUpdate = onSpmUpdate
    }

    var body: some View {
        Form {
            Section {
                HStack {
                    Image(systemName: "figure.walk")
                        .frame(width:20, height: 20)
                    Text("SPM (Cadence)")
                    AutoFocusTextField(text: $spmValue, onCommit: saveSpm)
                        .keyboardType(.decimalPad)
                        .onChange(of: spmValue) { oldValue, newValue in
                            spmValue = filterNumericInput(newValue) // 🎯 入力バリデーション
                        }
                }
            }
        }
        .navigationTitle("Step Per Minute")
    }

    private func saveSpm() {
        if let newSpm = Double(spmValue) {
            onSpmUpdate(newSpm)
        } else {
            print("無効な SPM 値")
        }
        presentationMode.wrappedValue.dismiss()
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

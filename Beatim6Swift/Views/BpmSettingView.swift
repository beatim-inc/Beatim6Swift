//
//  BpmSettingView.swift
//  Beatim6Swift
//
//  Created by 野村健介 on 2025/02/19.
//

import Foundation
import SwiftUI
import UIKit

struct BpmSettingView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var bpmValue: String
    var onBpmUpdate: (Double) -> Void
    @Binding var bpmErrorMessage: String

    init(bpm: Double, bpmErrorMessage: Binding<String>, onBpmUpdate: @escaping (Double) -> Void) {
        _bpmValue = State(initialValue: String(format: "%.1f", bpm))
        self._bpmErrorMessage = bpmErrorMessage
        self.onBpmUpdate = onBpmUpdate
    }

    var body: some View {
        Form {
            Section {
                HStack {
                    Image("Bpm")
                        .resizable()
                        .renderingMode(.template)
                        .foregroundColor(.primary)
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                    Text("Original BPM :")
                    AutoFocusTextField(text: $bpmValue, onCommit: saveBpm)
                        .keyboardType(.decimalPad)
                        .onChange(of: bpmValue) { oldValue, newValue in
                            bpmValue = filterNumericInput(newValue) // 🎯 入力バリデーション
                        } 
                }
            }
        }
        .navigationTitle("Original BPM")
    }

    private func saveBpm() {
        if let newBpm = Double(bpmValue) {
            onBpmUpdate(newBpm)
            bpmErrorMessage = ""
        } else {
            print("無効な BPM 値")
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

// 🎯 自動フォーカス & "Done" ボタン付き UITextField ラッパー
struct AutoFocusTextField: UIViewRepresentable {
    @Binding var text: String
    var onCommit: () -> Void

    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField()
        textField.text = text
        textField.borderStyle = .none // SwiftUI のスタイルを維持
        textField.backgroundColor = .clear
        textField.keyboardType = .decimalPad
        textField.textAlignment = .left
        textField.delegate = context.coordinator
        
        // 🎯 キーボード上部に "Done" ボタンを追加
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let doneButton = UIBarButtonItem(title: "Done", style: .done, target: context.coordinator, action: #selector(Coordinator.doneTapped))
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        toolbar.setItems([flexSpace, doneButton], animated: false)
        textField.inputAccessoryView = toolbar

        return textField
    }

    func updateUIView(_ uiView: UITextField, context: Context) {
        if uiView.text != text {
            uiView.text = text
        }
        DispatchQueue.main.async {
            if !uiView.isFirstResponder {
                uiView.becomeFirstResponder() // 🎯 自動フォーカス
                uiView.selectAll(nil) // 🎯 すべて選択
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UITextFieldDelegate {
        var parent: AutoFocusTextField

        init(_ parent: AutoFocusTextField) {
            self.parent = parent
        }

        func textFieldDidChangeSelection(_ textField: UITextField) {
            DispatchQueue.main.async {
                self.parent.text = textField.text ?? ""
            }
        }

        @objc func doneTapped() {
            parent.onCommit() // 🎯 "Done" ボタンで Save を実行
        }
    }
}

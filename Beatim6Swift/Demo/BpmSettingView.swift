//
//  BpmSettingView.swift
//  Beatim6Swift
//
//  Created by 野村健介 on 2025/02/19.
//

import Foundation
import SwiftUI

struct BpmSettingView: View {
    var bpm:Double

    var body: some View {
        Form {
                Section(header: Text("BPM 設定")) {
                    //TextField("BPM を入力",text: bpm)
                            .keyboardType(.numberPad)
                    }
                    Section {
                        Button("保存") {
                        //TODO:保存
                            print("BPM 設定: \(bpm)")
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
        .navigationTitle("BPM Setting")
    }
}

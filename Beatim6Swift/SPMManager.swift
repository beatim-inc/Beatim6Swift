//
//  SPMManager.swift
//  Beatim6Swift
//
//  Created by 野村健介 on 2025/02/17.
//

import Foundation
import SwiftUI

final class SPMManager: ObservableObject {
    //インターバル
    private var intervals: [TimeInterval] = []
    //SPM
    @Published private(set) var spm: Double = 0.0
    //最後に足を着けた時刻
    //Timer等を使用した方がパフォーマンスが上がるかも?
    private var lastStepTime: Date?

    func start() {
        intervals.removeAll()
        lastStepTime = Date()
    }
    
    func addStepData() {
        let interval = Date().timeIntervalSince(lastStepTime!)
        intervals.append(interval)
    }

    func calculateSPM() {
        guard !intervals.isEmpty else {
            spm = 0.0
            return
        }
        //必要に応じて外れ値を除去
        let totalTime = intervals.last! - intervals.first!
        let stepCount = Double(intervals.count)
        spm = (stepCount / totalTime) * 60.0
        print(spm)
    }

    func stop() {
    }
}

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
    @Published var spm: Double = 0.0
    @Published var lastUpdatedSPM: Double = 0.0
    @Published var allowStepUpdate: Bool = true
    //最後に足を着けた時刻
    //Timer等を使用した方がパフォーマンスが上がるかも?
    private var lastStepTime: Date?

    func start() {
        intervals.removeAll()
        lastStepTime = Date()
    }
    
    func addStepData() {
        let now = Date()
        if let lastTime = lastStepTime {
            let interval = now.timeIntervalSince(lastTime)
            intervals.append(interval)

            if intervals.count == 10 {
                calculateSPM()
                intervals.removeAll() // SPM計算後にintervalsをクリア
            }
        }
        lastStepTime = now
    }

    func calculateSPM() {
        guard intervals.count == 10 else {
            spm = 0.0
            return
        }
        
        // 最大値と最小値を除いた配列を作成
        let sortedIntervals = intervals.sorted()
        let filteredIntervals = sortedIntervals[1..<9] // 最大値と最小値を除いた8個のデータ
        
        let totalTime = filteredIntervals.reduce(0, +)
        let stepCount = Double(filteredIntervals.count)
        
        spm = (stepCount / totalTime) * 60.0
        print("Updated SPM: \(spm)")
    }

    func stop() {
    }
}

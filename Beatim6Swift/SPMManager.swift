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
    @Published var lastUpdatedSPM: Double = 0.0
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
        }
        lastStepTime = now
    }

    func calculateSPM() {
        guard !intervals.isEmpty else {
            spm = 0.0
            return
        }
        
        // 直近10ステップ（またはそれ未満）のデータを取得
        let recentIntervals = Array(intervals.suffix(10))
        
        guard recentIntervals.count > 2 else { // 四分位範囲を計算するために最低3つ以上必要
            let totalTime = recentIntervals.reduce(0, +)
            let stepCount = Double(recentIntervals.count)
            spm = stepCount > 0 ? (stepCount / totalTime) * 60.0 : 0.0
            print(spm)
            return
        }
        
        // ソートして四分位数を計算
        let sortedIntervals = recentIntervals.sorted()
        let q1Index = Int(Double(sortedIntervals.count - 1) * 0.25)
        let q3Index = Int(Double(sortedIntervals.count - 1) * 0.75)
        
        let q1 = sortedIntervals[q1Index]
        let q3 = sortedIntervals[q3Index]
        
        // Q1 以上 Q3 以下の値のみをフィルタ
        let filteredIntervals = sortedIntervals.filter { $0 >= q1 && $0 <= q3 }
        
        guard !filteredIntervals.isEmpty else {
            spm = 0.0
            return
        }
        
        let totalTime = filteredIntervals.reduce(0, +) // 合計時間
        let stepCount = Double(filteredIntervals.count)
        
        spm = (stepCount / totalTime) * 60.0
        print(spm)
    }

    func stop() {
    }
}

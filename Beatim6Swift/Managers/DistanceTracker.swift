//
//  DistanceTracker.swift
//  IndoorDistanceMeter
//
//  Created by heilab on 2025-04-09.
//

import Foundation
import ARKit
import simd
import Charts

class DistanceTracker: NSObject, ObservableObject, ARSessionDelegate {
    private let session = ARSession()
    private var lastPosition: simd_float3?
    private var startTime: TimeInterval?
    private var lastTimestamp: TimeInterval?

    @Published var distance: Float = 0.0
    @Published var speed: Float = 0.0
    @Published var isRunning = false
    @Published var speedHistory: [SpeedSample] = []
    @Published var latestTimestamp: TimeInterval = 0.0
    private let historyDuration: TimeInterval = 10.0

    func start() {
        session.pause() // 安全のため一度止めてから

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let config = ARWorldTrackingConfiguration()
            self.startTime = nil
            self.session.delegate = self
            self.session.run(config, options: [.resetTracking, .removeExistingAnchors])
            self.startTime = Date().timeIntervalSince1970
            self.lastPosition = nil
            self.distance = 0.0
            self.speed = 0.0
            self.speedHistory.removeAll()
            self.isRunning = true
        }
    }

    func stop() {
        session.pause()
        isRunning = false
    }

    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        guard isRunning else { return }

        let currentPosition = frame.camera.transform.columns.3.xyz
        let currentTime = frame.timestamp

        // 無効なベクトルは無視（NaNやInf）
        guard currentPosition.isValid else { return }
        
        // デフォルトで速度を0にしておく（動かないと0のまま）
        var currentSpeed: Float = 0.0

        if let last = lastPosition, let lastTime = lastTimestamp {
            let delta = currentPosition - last
            let stepDistance = simd_length(delta)
            let deltaTime = Float(currentTime - lastTime)

            // 極端な距離やNaNを除外（ノイズ対策）
            if stepDistance.isFinite, stepDistance > 0.001, stepDistance < 2.0, deltaTime > 0.01, deltaTime < 1.0 {
                distance += stepDistance
                currentSpeed = stepDistance / deltaTime * 3.6  /*  m/sをkm/hに変換  */
            }
        }
        
        speed = currentSpeed
        // ← グラフ用に履歴を追加
        let now = Date().timeIntervalSince1970
        let relativeTime = now - (startTime ?? now)
        let sample = SpeedSample(timestamp: relativeTime, speed: speed)
        speedHistory.append(sample)

        lastPosition = currentPosition
        lastTimestamp = currentTime
        latestTimestamp = relativeTime
    }
}

extension simd_float4 {
    var xyz: simd_float3 {
        return simd_make_float3(x, y, z)
    }
}

extension simd_float3 {
    var isValid: Bool {
        return x.isFinite && y.isFinite && z.isFinite
    }
}

struct SpeedSample: Identifiable {
    let id = UUID()
    let timestamp: TimeInterval // startからの相対秒
    let speed: Float            // m/s
}

//
//  SoundManager.swift
//  Beatim6Swift
//
//  Created by 野村健介 on 2025/02/17.
//

import SwiftUI
import CoreBluetooth
import AVFoundation

class StepSoundManager: ObservableObject {
    static let shared = StepSoundManager()
    var audioPlayer: AVAudioPlayer?
    @Published var rightStepSoundName = "DJ Drum" // soundName を変更可能にする
    @Published var leftStepSoundName = "Clap"
    private var timer: Timer?
    private var isStepSoundRight: Bool = false
    @Published var isPeriodicStepSoundActive: Bool = false
    @Published var isDelayedStepSoundActive = false
    private let maxDelayTime = 0.7
    private let minDelayTime = 0.0
    @Published var rightStepVolume: Float = 1.0
    @Published var leftStepVolume: Float = 1.0

    init() {
        setupAudioSession()
    }

    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set audio session: \(error)")
        }
    }

    func setRightStepSoundName(to newSoundName: String) {
        rightStepSoundName = newSoundName
    }
    
    func setLeftStepSoundName(to newSoundName: String) {
        leftStepSoundName = newSoundName
    }
    
    func setRightStepVolume(_ volume: Float) {
        rightStepVolume = max(0.0, min(volume, 1.0))  // 0.0〜1.0に制限
    }

    func setLeftStepVolume(_ volume: Float) {
        leftStepVolume = max(0.0, min(volume, 1.0))  // 0.0〜1.0に制限
    }

    func playSoundOnce(soundName: String, volume: Float) {
        guard let url = Bundle.main.url(forResource: soundName, withExtension: "mp3") else {
            print("⚠️ Error: Sound file '\(soundName).mp3' not found")
            return
        }
        
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.volume = volume
            player.prepareToPlay()
            player.play()
            
            // メモリ管理のため、直前のインスタンスを解放してから新しいインスタンスを保持
            audioPlayer?.stop()
            audioPlayer = player
        } catch {
            print("⚠️ Error playing sound '\(soundName)': \(error.localizedDescription)")
        }
    }
    
    private func playDelayedSoundOnce(soundName: String, volume: Float){
        let delay = Double.random(in: minDelayTime...maxDelayTime)
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            self.playSoundOnce(soundName: soundName, volume: volume)
        }
    }
    
    func playRightStepSound() {
        guard !isPeriodicStepSoundActive else { return }

        DispatchQueue.global(qos: .userInitiated).async {
            if self.isDelayedStepSoundActive {
                self.playDelayedSoundOnce(soundName: self.rightStepSoundName, volume: self.rightStepVolume)
            } else {
                self.playSoundOnce(soundName: self.rightStepSoundName, volume: self.rightStepVolume)
            }
        }
    }

    func playLeftStepSound() {
        guard !isPeriodicStepSoundActive else { return }

        DispatchQueue.global(qos: .userInitiated).async {
            if self.isDelayedStepSoundActive {
                self.playDelayedSoundOnce(soundName: self.leftStepSoundName, volume: self.leftStepVolume)
            } else {
                self.playSoundOnce(soundName: self.leftStepSoundName, volume: self.leftStepVolume)
            }
        }
    }
    
    func playSoundPeriodically(BPM: Double) {
        if(BPM <= 0){return;}
        if(isPeriodicStepSoundActive){
            timer?.invalidate()
            let interval = 60.0 / BPM
            timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
                if(self?.isPeriodicStepSoundActive == true){
                    if(self?.isStepSoundRight == true){
                        self?.playSoundOnce(soundName:self?.rightStepSoundName ?? "", volume: self?.rightStepVolume ?? 1.0)
                    }else{
                        self?.playSoundOnce(soundName: self?.leftStepSoundName ?? "", volume: self?.leftStepVolume ?? 1.0)
                    }
                    if(self?.isStepSoundRight != nil){
                        self!.isStepSoundRight = !self!.isStepSoundRight
                    }
                }
            }
        }
    }
    func stopPeriodicSound() {
        timer?.invalidate()
        timer = nil
    }
}

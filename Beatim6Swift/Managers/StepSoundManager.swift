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
    @Published var soundName = "Crap" // soundName を変更可能にする
    private var timer: Timer?
    @Published var isPeriodicStepSoundActive: Bool = false

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

    func setSoundName(to newSoundName: String) {
        soundName = newSoundName
    }

    private func playSoundOnce() {
        if let url = Bundle.main.url(forResource: soundName, withExtension: "mp3") {
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: url)
                audioPlayer?.play()
            } catch {
                print("Error playing sound: \(error.localizedDescription)")
            }
        } else {
            print("Error finding sound file")
        }
    }
    
    func playSound(){
        if(!isPeriodicStepSoundActive){playSoundOnce()}
    }
    
    func playSoundPeriodically(BPM: Double) {
        if(BPM <= 0){return;}
        if(isPeriodicStepSoundActive){
            timer?.invalidate()
            let interval = 60.0 / BPM
            timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
                if(self?.isPeriodicStepSoundActive == true){self?.playSoundOnce()}
            }
        }
    }
    func stopPeriodicSound() {
        timer?.invalidate()
        timer = nil
    }
}

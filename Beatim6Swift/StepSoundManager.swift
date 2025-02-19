//
//  SoundManager.swift
//  Beatim6Swift
//
//  Created by 野村健介 on 2025/02/17.
//

import SwiftUI
import CoreBluetooth
import AVFoundation

class StepSoundManager {
    static let shared = StepSoundManager()
    var audioPlayer: AVAudioPlayer?
    let soundName = "step_sound"

    
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
    
    
    func playSound() {
        if let url = Bundle.main.url(forResource: soundName,withExtension:"mp3") {
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: url)
                audioPlayer?.play()
            } catch {
                print("Error playing sound: \(error.localizedDescription)")
            }
        }else{
            print("Error finding sound file")
        }
    }
}

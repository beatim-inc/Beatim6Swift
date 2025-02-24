//
//  PlayMusicView.swift
//  MusicKit_Demo
//
//  Created by Shunzhe on 2022/01/22.
//

import SwiftUI
import MusicKit

struct SongInfoView: View {
    @EnvironmentObject var stepSoundManager: StepSoundManager
    @EnvironmentObject var spmManager: SPMManager
    var songItem: Song
    var musicDefaultbpm: Double

    
    var body: some View {         
        // Play using app player
        Button(action: {
            Task {
                ApplicationMusicPlayer.shared.queue = .init(for: [songItem])
                do {
                    try await ApplicationMusicPlayer.shared.prepareToPlay()
                    stepSoundManager.playSoundPeriodically(BPM:spmManager.spm)
                    ApplicationMusicPlayer.shared.state.playbackRate =
                    (spmManager.spm > 0 ?
                    Float(spmManager.spm/musicDefaultbpm) : 1.0)
//                        try await ApplicationMusicPlayer.shared.play() //これを入れると再生速度が1になってしまう
                    print(ApplicationMusicPlayer.shared.state.playbackRate)
                    print(ApplicationMusicPlayer.shared.state.playbackStatus)
                } catch {
                    print(error.localizedDescription)
                }
            }
        }) {
            // Song info
            HStack(alignment: .center) {
                if let artwork = songItem.artwork {
                    ArtworkImage(artwork, height: 40)
                }
                VStack(alignment: .leading) {
                    Text(songItem.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text("\(songItem.artistName) \(songItem.albumTitle ?? "")")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
        }
    }
    
}

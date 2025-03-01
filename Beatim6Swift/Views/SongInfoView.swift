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
        // Music Player
        Button(action: {
            Task {
                ApplicationMusicPlayer.shared.queue = .init(for: [songItem])
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

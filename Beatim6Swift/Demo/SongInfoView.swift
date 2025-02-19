//
//  PlayMusicView.swift
//  MusicKit_Demo
//
//  Created by Shunzhe on 2022/01/22.
//

import SwiftUI
import MusicKit

struct SongInfoView: View {
    
    var songItem: Song
    
    var body: some View {
        Section {
            // Song info
            HStack {
                VStack {
                    Text(songItem.title)
                    Text("\(songItem.artistName) \(songItem.albumTitle ?? "")")
                    if let artwork = songItem.artwork {
                        ArtworkImage(artwork, height: 100)
                    }
                }
            }
//            // Play using system player
//            Button("Play using iOS system player") {
//                Task {
//                    SystemMusicPlayer.shared.queue = .init(for: [songItem])
//                    do {
//                        try await SystemMusicPlayer.shared.play()
//                    } catch {
//                        print(error.localizedDescription)
//                    }
//                }
//            }
            // Play using app player
            Button("Play using in-app player") {
                Task {
                    ApplicationMusicPlayer.shared.queue = .init(for: [songItem])
                    do {
                        try await ApplicationMusicPlayer.shared.prepareToPlay()
                        ApplicationMusicPlayer.shared.state.playbackRate = 1.0
//                        try await ApplicationMusicPlayer.shared.play() //これを入れると再生速度が1になってしまう
                        print(ApplicationMusicPlayer.shared.state.playbackRate)
                        print(ApplicationMusicPlayer.shared.state.playbackStatus)
                    } catch {
                        print(error.localizedDescription)
                    }
                }
            }
            Button("Speed UP") {
                Task {
                    ApplicationMusicPlayer.shared.state.playbackRate += 0.1
                    print(ApplicationMusicPlayer.shared.state.playbackRate)
                }
            }
            Button("Speed DOWN") {
                Task {
                    ApplicationMusicPlayer.shared.state.playbackRate -= 0.1
                    print(ApplicationMusicPlayer.shared.state.playbackRate)
                }
            }
        }
    }
    
}

//
//  SearchPlaylistView.swift
//  Beatim Watch
//
//  Created by ryota on 2024/04/28.
//

import SwiftUI
import MusicKit

struct SearchPlaylistView: View {
    
    @ObservedObject var viewModel: SearchPlaylistViewModel

    @FocusState private var isSearchFieldFocused: Bool // 🎯 フォーカス状態を管理
    
    // ユーザーライブラリへのアクセスにはMusicSubscriptionではなく、
    // MusicLibraryへの権限確認が必要です（ここでは簡略化しています）。
    
    var body: some View {
        
        Form {
            
            Section {
                TextField("Search term", text: $viewModel.searchTerm)
                    .focused($isSearchFieldFocused) // 🎯 フォーカス適用
                    .submitLabel(.search)
                    .onSubmit {
                        Task {
                            await viewModel.performSearch()
                        }
                    }
            }
            
            if viewModel.isPerformingSearch {
                ProgressView()
            }
            
            ForEach(viewModel.searchResultPlaylists) { playlist in
                NavigationLink {
                    PlaylistDetailsView(playlist: playlist)
                } label: {
                    HStack {
                        if let artwork = playlist.artwork {
                            ArtworkImage(artwork, height: 40)
                        }
                        VStack(alignment: .leading) {
                            Text(playlist.name)
                            // 必要に応じてその他の情報も表示
                        }
                    }
                }
            }
        }
        .navigationTitle("Search Playlists")
        .onAppear {
            isSearchFieldFocused = true // 🎯 画面表示時に自動フォーカス
        }
    }
}

/*
 自作プレイリストの詳細を表示するビュー
 */
struct PlaylistDetailsView: View {
    
    @State private var updatedPlaylistObject: Playlist?
    var playlist: Playlist

    var body: some View {
        
        Form {
            
            Section{
                // アプリ内プレイヤーで再生
                Button("Play the entire playlist") {
                    Task {
                        ApplicationMusicPlayer.shared.queue = .init(for: [playlist])
                        do {
                            try await ApplicationMusicPlayer.shared.play()
                        } catch {
                            print(error.localizedDescription)
                        }
                    }
                }
            }
            
            
            if let tracks = self.updatedPlaylistObject?.tracks {
                ForEach(tracks) { track in
                    switch track {
                    case .song(let songItem):
                        SongInfoView(songItem: songItem, musicDefaultbpm: 120)
                    case .musicVideo(_):
                        EmptyView()
                    @unknown default:
                        EmptyView()
                    }
                }
            } else {
                ProgressView("Loading tracks...")
            }
            
        }
        .task {
            // プレイリストの詳細情報（トラック情報など）を取得
            self.updatedPlaylistObject = try? await playlist.with([.tracks])
        }
        
    }
}


//
//  SearchPlaylistView.swift
//  Beatim Watch
//
//  Created by ryota on 2024/04/28.
//

import SwiftUI
import MusicKit

struct SearchPlaylistView: View {
    
    @State private var searchTerm: String = ""
    @State private var searchResultPlaylists: MusicItemCollection<Playlist> = []
    @State private var isPerformingSearch: Bool = false
    
    // ユーザーライブラリへのアクセスにはMusicSubscriptionではなく、
    // MusicLibraryへの権限確認が必要です（ここでは簡略化しています）。
    
    var body: some View {
        
        Form {
            
            Section {
                TextField("Search term", text: $searchTerm)
            }
            
            Button("Perform search") {
                Task {
                    do {
                        // ユーザーライブラリ内のプレイリストを検索するためにMusicLibrarySearchRequestを使用
                        let request = MusicLibrarySearchRequest(term: searchTerm, types: [Playlist.self])
                        self.isPerformingSearch = true
                        let response = try await request.response()
                        self.isPerformingSearch = false
                        self.searchResultPlaylists = response.playlists
                        print("playlists: \(self.searchResultPlaylists)")
                    } catch {
                        print(error.localizedDescription)
                        // エラーハンドリング（必要に応じてエラーメッセージの表示等）
                    }
                }
            }
            .disabled(isPerformingSearch)
            
            if isPerformingSearch {
                ProgressView()
            }
            
            ForEach(self.searchResultPlaylists) { playlist in
                NavigationLink {
                    PlaylistDetailsView(playlist: playlist)
                } label: {
                    HStack {
                        if let artwork = playlist.artwork {
                            ArtworkImage(artwork, height: 100)
                        }
                        VStack(alignment: .leading) {
                            Text(playlist.name)
                            // 必要に応じてその他の情報も表示
                        }
                    }
                }
            }
            
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
            
            Section("再生オプション") {
                // システムプレイヤーで再生
                Button("Play using iOS system player") {
                    Task {
                        SystemMusicPlayer.shared.queue = .init(for: [playlist])
                        do {
                            try await SystemMusicPlayer.shared.play()
                        } catch {
                            print(error.localizedDescription)
                        }
                    }
                }
                // アプリ内プレイヤーで再生
                Button("Play using in-app player") {
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
            
            // プレイリストの固有IDを表示
            Text("Playlist ID: \(playlist.id)")
            
            if let tracks = self.updatedPlaylistObject?.tracks {
                ForEach(tracks) { track in
                    switch track {
                    case .song(let songItem):
                        SongInfoView(songItem: songItem)
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


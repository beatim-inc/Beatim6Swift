//
//  SearchAlbumView.swift
//  MusicKit_Demo
//
//  Created by Shunzhe on 2022/01/22.
//

import SwiftUI
import MusicKit

struct SearchAlbumView: View {
    
    @State private var searchTerm: String = ""
    @State private var searchResultAlbums: MusicItemCollection<Album> = []
    @State private var isPerformingSearch: Bool = false
    @State private var musicSubscription: MusicSubscription?
    private var resultLimit: Int = 5

    @FocusState private var isSearchFieldFocused: Bool // 🎯 フォーカス状態を管理
    
    var body: some View {
        
        Form {
            
            Section {
                TextField("Search term", text: $searchTerm)
                    .focused($isSearchFieldFocused) // 🎯 フォーカス適用
                    .onSubmit {
                        performSearch()
                    }
            }
            
            if isPerformingSearch {
                ProgressView()
            }
            
            ForEach(self.searchResultAlbums) { album in
                NavigationLink {
                    AlbumDetailsView(album: album)
                } label: {
                    HStack(alignment: .center) {
                        if let artwork = album.artwork {
                            ArtworkImage(artwork, height: 40)
                        }
                        VStack(alignment: .leading) {
                            Text(album.title)
                                .font(.headline) // タイトルを大きく
                                .foregroundColor(.primary) // 通常の色
                            Text(album.artistName)
                                .font(.subheadline) // アーティスト名を小さく
                                .foregroundColor(.gray) // 灰色に
                        }
                    }
                }
            }
            
        }
        .navigationTitle("Search Albums")
        .onAppear {
            isSearchFieldFocused = true // 🎯 画面表示時に自動フォーカス
        }
        .task {
            for await subscription in MusicSubscription.subscriptionUpdates {
                self.musicSubscription = subscription
            }
        }
        
    }
    
    // 🎯 検索処理をメソッド化（Enterキー & ボタン 両方で使用）
    private func performSearch() {
        Task {
            do {
                let request = MusicCatalogSearchRequest(term: searchTerm, types: [Album.self])
                self.isPerformingSearch = true
                let response = try await request.response()
                self.isPerformingSearch = false
                self.searchResultAlbums = response.albums
            } catch {
                print("Error: \(error.localizedDescription)")
            }
        }
    }
}

/*
 A view that shows all the songs within an album
 */
struct AlbumDetailsView: View {
    
    @State private var updatedAlbumObject: Album?

    var album: Album

    var body: some View {
        
        Form {
            // Play using app player
            Section {
                Button("Play the album") {
                    Task {
                        ApplicationMusicPlayer.shared.queue = .init(for: [album])
                        do {
                            try await ApplicationMusicPlayer.shared.play()
                        } catch {
                            print(error.localizedDescription)
                        }
                    }
                }
            }
            
            if let tracks = self.updatedAlbumObject?.tracks {
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
            self.updatedAlbumObject = try? await album.with([.tracks])
        }
        
    }

}




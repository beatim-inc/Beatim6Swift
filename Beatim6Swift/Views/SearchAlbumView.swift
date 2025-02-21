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
    
    var body: some View {
        
        Form {
            
            Section {
                TextField("Search term", text: $searchTerm)
                    .onSubmit {
                        performSearch()
                    }
            }
            
            // Button("Perform search") {
            //     performSearch()
            // }
            // .disabled(!(musicSubscription?.canPlayCatalogContent ?? false) || isPerformingSearch)
            
            if isPerformingSearch {
                ProgressView()
            }
            
            ForEach(self.searchResultAlbums) { album in
                NavigationLink {
                    AlbumDetailsView(album: album)
                } label: {
                    HStack {
                        if let artwork = album.artwork {
                            ArtworkImage(artwork, height: 100)
                        }
                        VStack {
                            Text(album.title)
                            Text(album.artistName)
                        }
                    }
                }
            }
            
        }
        .navigationTitle("Search Albums")
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
            
            Section("Play the entier album") {
                // Play using system player
                Button("Play using iOS system player") {
                    Task {
                        SystemMusicPlayer.shared.queue = .init(for: [album])
                        do {
                            try await SystemMusicPlayer.shared.play()
                        } catch {
                            print(error.localizedDescription)
                        }
                    }
                }
                // Play using app player
                Button("Play using in-app player") {
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
            
            Text("Album ID: \(album.url?.absoluteString ?? "")")
            Text("There's a total of \(album.trackCount) tracks.")
            
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




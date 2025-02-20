//
//  SearchSongsView.swift
//  MusicKit_Demo
//
//  Created by Shunzhe on 2022/01/22.
//

import SwiftUI
import MusicKit

struct SearchSongsView: View {
    
    @State private var searchTerm: String = ""
    @State private var searchResultSongs: MusicItemCollection<Song> = []
    @State private var isPerformingSearch: Bool = false
    @State private var musicSubscription: MusicSubscription?
    private var resultLimit: Int = 5
    
    var body: some View {
        
        Form {
            
            Section {
                TextField("Search term", text: $searchTerm)
                    .onSubmit { // 🎯 Enter キーで検索実行
                        performSearch()
                    }
            }
            
            if isPerformingSearch {
                ProgressView()
            }
            
            ForEach(self.searchResultSongs) { song in
                SongInfoView(songItem: song)
            }
            
        }
        .navigationTitle("Search Songs")
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
                let request = MusicCatalogSearchRequest(term: searchTerm, types: [Song.self])
                self.isPerformingSearch = true
                let response = try await request.response()
                self.isPerformingSearch = false
                self.searchResultSongs = response.songs
            } catch {
                print("Error: \(error.localizedDescription)")
            }
        }
    }
    
}

